# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::GitAccess do
  include GitHelpers
  include EE::GeoHelpers

  set(:user) { create(:user) }

  let(:actor) { user }
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:namespace_path) { nil }
  let(:project_path) { nil }
  let(:protocol) { 'web' }
  let(:authentication_abilities) { %i[read_project download_code push_code] }
  let(:redirected_path) { nil }

  context "when in a read-only GitLab instance" do
    before do
      create(:protected_branch, name: 'feature', project: project)
      allow(Gitlab::Database).to receive(:read_only?) { true }
    end

    let(:primary_repo_url) { geo_primary_http_url_to_repo(project) }
    let(:primary_repo_ssh_url) { geo_primary_ssh_url_to_repo(project) }

    it_behaves_like 'a read-only GitLab instance'
  end

  describe "push_rule_check" do
    let(:start_sha) { '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9' }
    let(:end_sha)   { '570e7b2abdd848b95f2f578043fc23bd6f6fd24d' }
    let(:changes)   { "#{start_sha} #{end_sha} refs/heads/master" }

    before do
      project.add_developer(user)

      allow(project.repository).to receive(:new_commits)
        .and_return(project.repository.commits_between(start_sha, end_sha))
    end

    describe "author email check" do
      it 'returns true' do
        expect { push_changes(changes) }.not_to raise_error
      end

      it 'returns false when a commit message is missing required matches (positive regex match)' do
        project.create_push_rule(commit_message_regex: "@only.com")

        expect { push_changes(changes) }.to raise_error(described_class::UnauthorizedError)
      end

      it 'returns false when a commit message contains forbidden characters (negative regex match)' do
        project.create_push_rule(commit_message_negative_regex: "@gmail.com")

        expect { push_changes(changes) }.to raise_error(described_class::UnauthorizedError)
      end

      it 'returns true for tags' do
        project.create_push_rule(commit_message_regex: "@only.com")

        expect { push_changes("#{start_sha} #{end_sha} refs/tags/v1") }.not_to raise_error
      end

      it 'allows githook for new branch with an old bad commit' do
        bad_commit = double("Commit", safe_message: 'Some change').as_null_object
        ref_object = double(name: 'heads/master')
        allow(bad_commit).to receive(:refs).and_return([ref_object])
        allow_any_instance_of(Repository).to receive(:commits_between).and_return([bad_commit])

        project.create_push_rule(commit_message_regex: "Change some files")

        # push to new branch, so use a blank old rev and new ref
        expect { push_changes("#{Gitlab::Git::BLANK_SHA} #{end_sha} refs/heads/new-branch") }.not_to raise_error
      end

      it 'allows githook for any change with an old bad commit' do
        bad_commit = double("Commit", safe_message: 'Some change').as_null_object
        ref_object = double(name: 'heads/master')
        allow(bad_commit).to receive(:refs).and_return([ref_object])
        allow(project.repository).to receive(:commits_between).and_return([bad_commit])

        project.create_push_rule(commit_message_regex: "Change some files")

        # push to new branch, so use a blank old rev and new ref
        expect { push_changes("#{start_sha} #{end_sha} refs/heads/master") }.not_to raise_error
      end

      it 'does not allow any change from Web UI with bad commit' do
        bad_commit = double("Commit", safe_message: 'Some change').as_null_object
        # We use tmp ref a a temporary for Web UI commiting
        ref_object = double(name: 'refs/tmp')
        allow(bad_commit).to receive(:refs).and_return([ref_object])
        allow(project.repository).to receive(:commits_between).and_return([bad_commit])
        allow(project.repository).to receive(:new_commits).and_return([bad_commit])

        project.create_push_rule(commit_message_regex: "Change some files")

        # push to new branch, so use a blank old rev and new ref
        expect { push_changes("#{start_sha} #{end_sha} refs/heads/master") }.to raise_error(described_class::UnauthorizedError)
      end
    end

    describe "member_check" do
      let(:changes) { "#{start_sha} #{end_sha} refs/heads/master" }

      before do
        project.create_push_rule(member_check: true)
      end

      it 'returns false for non-member user' do
        expect { push_changes(changes) }.to raise_error(described_class::UnauthorizedError)
      end

      it 'returns true if committer is a gitlab member' do
        create(:user, email: 'dmitriy.zaporozhets@gmail.com')

        expect { push_changes(changes) }.not_to raise_error
      end
    end

    describe "file names check" do
      let(:start_sha) { '913c66a37b4a45b9769037c55c2d238bd0942d2e' }
      let(:end_sha) { '33f3729a45c02fc67d00adb1b8bca394b0e761d9' }
      let(:changes) { "#{start_sha} #{end_sha} refs/heads/master" }

      before do
        allow(project.repository).to receive(:new_commits)
          .and_return(project.repository.commits_between(start_sha, end_sha))
      end

      it 'returns false when filename is prohibited' do
        project.create_push_rule(file_name_regex: "jpg$")

        expect { push_changes(changes) }.to raise_error(described_class::UnauthorizedError)
      end

      it 'returns true if file name is allowed' do
        project.create_push_rule(file_name_regex: "exe$")

        expect { push_changes(changes) }.not_to raise_error
      end
    end

    describe "max file size check" do
      let(:start_sha) { ::Gitlab::Git::BLANK_SHA }
      # SHA of the 2-mb-file branch
      let(:end_sha)   { 'bf12d2567099e26f59692896f73ac819bae45b00' }
      let(:changes) { "#{start_sha} #{end_sha} refs/heads/my-branch" }

      before do
        project.add_developer(user)
        # Delete branch so Repository#new_blobs can return results
        repository.delete_branch('2-mb-file')
      end

      it "returns false when size is too large" do
        project.create_push_rule(max_file_size: 1)

        expect(repository.new_blobs(end_sha)).to be_present
        expect { push_changes(changes) }.to raise_error(described_class::UnauthorizedError)
      end

      it "returns true when size is allowed" do
        project.create_push_rule(max_file_size: 3)

        expect(repository.new_blobs(end_sha)).to be_present
        expect { push_changes(changes) }.not_to raise_error
      end
    end
  end

  describe 'repository size restrictions' do
    # SHA for the 2-mb-file branch
    let(:sha_with_2_mb_file) { 'bf12d2567099e26f59692896f73ac819bae45b00' }
    # SHA for the wip branch
    let(:sha_with_smallest_changes) { 'b9238ee5bf1d7359dd3b8c89fd76c1c7f8b75aba' }

    before do
      project.add_developer(user)
      # Delete branch so Repository#new_blobs can return results
      repository.delete_branch('2-mb-file')
      repository.delete_branch('wip')

      allow(project).to receive(:repository_and_lfs_size).and_return(repository_size)
      project.update_attribute(:repository_size_limit, repository_size_limit)
    end

    shared_examples_for 'a push to repository over the limit' do
      it 'rejects the push' do
        expect do
          push_changes("#{Gitlab::Git::BLANK_SHA} #{sha_with_smallest_changes} refs/heads/master")
        end.to raise_error(described_class::UnauthorizedError, /Your push has been rejected/)
      end

      context 'when deleting a branch' do
        it 'accepts the operation' do
          expect do
            push_changes("#{sha_with_smallest_changes} #{::Gitlab::Git::BLANK_SHA} refs/heads/feature")
          end.not_to raise_error
        end
      end
    end

    shared_examples_for 'a push to repository below the limit' do
      context 'when trying to authenticate the user' do
        it 'does not raise an error' do
          expect { push_changes }.not_to raise_error
        end
      end

      context 'when pushing a new branch' do
        it 'accepts the push' do
          master_sha = project.commit('master').id

          expect do
            push_changes("#{Gitlab::Git::BLANK_SHA} #{master_sha} refs/heads/my_branch")
          end.not_to raise_error
        end
      end
    end

    shared_examples_for 'a push to repository using git-rev-list for checking against repository size limit' do
      context 'when repository size is over limit' do
        let(:repository_size) { 2.megabytes }
        let(:repository_size_limit) { 1.megabyte }

        it_behaves_like 'a push to repository over the limit'
      end

      context 'when repository size is below the limit' do
        let(:repository_size) { 1.megabyte }
        let(:repository_size_limit) { 2.megabytes }

        it_behaves_like 'a push to repository below the limit'

        context 'when new change exceeds the limit' do
          it 'rejects the push' do
            expect(repository.new_blobs(sha_with_2_mb_file)).to be_present

            expect do
              push_changes("#{Gitlab::Git::BLANK_SHA} #{sha_with_2_mb_file} refs/heads/my_branch_2")
            end.to raise_error(described_class::UnauthorizedError, /Your push to this repository would cause it to exceed the size limit/)
          end
        end

        context 'when new change does not exceed the limit' do
          it 'accepts the push' do
            expect(repository.new_blobs(sha_with_smallest_changes)).to be_present

            expect do
              push_changes("#{Gitlab::Git::BLANK_SHA} #{sha_with_smallest_changes} refs/heads/my_branch_3")
            end.not_to raise_error
          end
        end
      end
    end

    context 'when GIT_OBJECT_DIRECTORY_RELATIVE env var is set' do
      before do
        allow(Gitlab::Git::HookEnv)
          .to receive(:all)
          .with(repository.gl_repository)
          .and_return({ 'GIT_OBJECT_DIRECTORY_RELATIVE' => 'objects' })

        # Stub the object directory size to "simulate" quarantine size
        allow(repository)
          .to receive(:object_directory_size)
          .and_return(object_directory_size)
      end

      let(:object_directory_size) { 1.megabyte }

      context 'when repository size is over limit' do
        let(:repository_size) { 2.megabytes }
        let(:repository_size_limit) { 1.megabyte }

        it_behaves_like 'a push to repository over the limit'
      end

      context 'when repository size is below the limit' do
        let(:repository_size) { 1.megabyte }
        let(:repository_size_limit) { 2.megabytes }

        it_behaves_like 'a push to repository below the limit'

        context 'when object directory (quarantine) size exceeds the limit' do
          let(:object_directory_size) { 2.megabytes }

          it 'rejects the push' do
            expect do
              push_changes("#{Gitlab::Git::BLANK_SHA} #{sha_with_2_mb_file} refs/heads/my_branch_2")
            end.to raise_error(described_class::UnauthorizedError, /Your push to this repository would cause it to exceed the size limit/)
          end
        end

        context 'when object directory (quarantine) size does not exceed the limit' do
          it 'accepts the push' do
            expect do
              push_changes("#{Gitlab::Git::BLANK_SHA} #{sha_with_smallest_changes} refs/heads/my_branch_3")
            end.not_to raise_error
          end
        end
      end
    end

    context 'when GIT_OBJECT_DIRECTORY_RELATIVE env var is not set' do
      it_behaves_like 'a push to repository using git-rev-list for checking against repository size limit'
    end
  end

  describe 'Geo' do
    let(:actor) { :geo }

    context 'git pull' do
      it { expect { pull_changes }.not_to raise_error }

      context 'for a secondary' do
        let(:current_replication_lag) { nil }

        before do
          stub_licensed_features(geo: true)
          stub_current_geo_node(create(:geo_node))

          allow_any_instance_of(Gitlab::Geo::HealthCheck).to receive(:db_replication_lag_seconds).and_return(current_replication_lag)
        end

        context 'that has no DB replication lag' do
          let(:current_replication_lag) { 0 }

          it 'does not return a replication lag message in the console messages' do
            expect(pull_changes.console_messages).to be_empty
          end
        end

        context 'that has DB replication lag > 0' do
          let(:current_replication_lag) { 7 }

          it 'returns a replication lag message in the console messages' do
            expect(pull_changes.console_messages).to eq(['Current replication lag: 7 seconds'])
          end
        end
      end
    end

    context 'git push' do
      it { expect { push_changes }.to raise_unauthorized(Gitlab::GitAccess::ERROR_MESSAGES[:upload]) }
    end
  end

  describe '#check_push_access!' do
    let(:project_path) { project.path }
    let(:namespace_path) { project&.namespace&.path }
    let(:protocol) { 'ssh' }
    let(:unprotected_branch) { 'unprotected_branch' }

    before do
      merge_into_protected_branch
    end

    let(:start_sha) { '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9' }
    let(:end_sha)   { '570e7b2abdd848b95f2f578043fc23bd6f6fd24d' }

    let(:changes) do
      { any: Gitlab::GitAccess::ANY,
        push_new_branch: "#{Gitlab::Git::BLANK_SHA} #{end_sha} refs/heads/wow",
        push_master: "#{start_sha} #{end_sha} refs/heads/master",
        push_protected_branch: "#{start_sha} #{end_sha} refs/heads/feature",
        push_remove_protected_branch: "#{end_sha} #{Gitlab::Git::BLANK_SHA} "\
                                      "refs/heads/feature",
        push_tag: "#{start_sha} #{end_sha} refs/tags/v1.0.0",
        push_new_tag: "#{Gitlab::Git::BLANK_SHA} #{end_sha} refs/tags/v7.8.9",
        push_all: ["#{start_sha} #{end_sha} refs/heads/master", "#{start_sha} #{end_sha} refs/heads/feature"],
        merge_into_protected_branch: "0b4bc9a #{merge_into_protected_branch} refs/heads/feature" }
    end

    def merge_into_protected_branch
      @protected_branch_merge_commit ||= begin
        project.repository.add_branch(user, unprotected_branch, 'feature')
        rugged = rugged_repo(project.repository)
        target_branch = rugged.rev_parse('feature')
        source_branch = project.repository.create_file(
          user,
          'filename',
          'This is the file content',
          message: 'This is a good commit message',
          branch_name: unprotected_branch)
        author = { email: "email@example.com", time: Time.now, name: "Example Git User" }

        merge_index = rugged.merge_commits(target_branch, source_branch)
        Rugged::Commit.create(rugged, author: author, committer: author, message: "commit message", parents: [target_branch, source_branch], tree: merge_index.write_tree(rugged))
      end
    end

    def self.run_permission_checks(permissions_matrix)
      permissions_matrix.each_pair do |role, matrix|
        # Run through the entire matrix for this role in one test to avoid
        # repeated setup.
        #
        # Expectations are given a custom failure message proc so that it's
        # easier to identify which check(s) failed.
        it "has the correct permissions for #{role}s" do
          if role == :admin
            user.update_attribute(:admin, true)
            project.add_guest(user)
          else
            project.add_role(user, role)
          end

          protected_branch.save

          aggregate_failures do
            matrix.each do |action, allowed|
              check = -> { push_changes(changes[action]) }

              if allowed
                expect(&check).not_to raise_error,
                  -> { "expected #{action} to be allowed" }
              else
                expect(&check).to raise_error(Gitlab::GitAccess::UnauthorizedError),
                  -> { "expected #{action} to be disallowed" }
              end
            end
          end
        end
      end
    end

    # Run permission checks for a group
    def self.run_group_permission_checks(permissions_matrix)
      permissions_matrix.each_pair do |role, matrix|
        it "has the correct permissions for group #{role}s" do
          project
            .project_group_links
            .create(group: group, group_access: Gitlab::Access.sym_options[role])

          protected_branch.save

          aggregate_failures do
            matrix.each do |action, allowed|
              check = -> { push_changes(changes[action]) }

              if allowed
                expect(&check).not_to raise_error,
                  -> { "expected #{action} to be allowed" }
              else
                expect(&check).to raise_error(Gitlab::GitAccess::UnauthorizedError),
                  -> { "expected #{action} to be disallowed" }
              end
            end
          end
        end
      end
    end

    permissions_matrix = {
      admin: {
        any: true,
        push_new_branch: true,
        push_master: true,
        push_protected_branch: true,
        push_remove_protected_branch: false,
        push_tag: true,
        push_new_tag: true,
        push_all: true,
        merge_into_protected_branch: true
      },

      maintainer: {
        any: true,
        push_new_branch: true,
        push_master: true,
        push_protected_branch: true,
        push_remove_protected_branch: false,
        push_tag: true,
        push_new_tag: true,
        push_all: true,
        merge_into_protected_branch: true
      },

      developer: {
        any: true,
        push_new_branch: true,
        push_master: true,
        push_protected_branch: false,
        push_remove_protected_branch: false,
        push_tag: true,
        push_new_tag: true,
        push_all: false,
        merge_into_protected_branch: false
      },

      reporter: {
        any: false,
        push_new_branch: false,
        push_master: false,
        push_protected_branch: false,
        push_remove_protected_branch: false,
        push_tag: false,
        push_new_tag: false,
        push_all: false,
        merge_into_protected_branch: false
      },

      guest: {
        any: false,
        push_new_branch: false,
        push_master: false,
        push_protected_branch: false,
        push_remove_protected_branch: false,
        push_tag: false,
        push_new_tag: false,
        push_all: false,
        merge_into_protected_branch: false
      }
    }

    [%w(feature exact), ['feat*', 'wildcard']].each do |protected_branch_name, protected_branch_type|
      context "user-specific access control" do
        let(:user) { create(:user) }

        context "when a specific user is allowed to push into the #{protected_branch_type} protected branch" do
          let(:protected_branch) { build(:protected_branch, authorize_user_to_push: user, name: protected_branch_name, project: project) }

          run_permission_checks(permissions_matrix.deep_merge(developer: { push_protected_branch: true, push_all: true, merge_into_protected_branch: true },
                                                              guest: { push_protected_branch: false, merge_into_protected_branch: false },
                                                              reporter: { push_protected_branch: false, merge_into_protected_branch: false }))
        end

        context "when a specific user is allowed to merge into the #{protected_branch_type} protected branch" do
          let(:protected_branch) { build(:protected_branch, authorize_user_to_merge: user, name: protected_branch_name, project: project) }

          before do
            create(:merge_request, source_project: project, source_branch: unprotected_branch, target_branch: 'feature', state: 'locked', in_progress_merge_commit_sha: merge_into_protected_branch)
          end

          run_permission_checks(permissions_matrix.deep_merge(admin: { push_protected_branch: false, push_all: false, merge_into_protected_branch: true },
                                                              maintainer: { push_protected_branch: false, push_all: false, merge_into_protected_branch: true },
                                                              developer: { push_protected_branch: false, push_all: false, merge_into_protected_branch: true },
                                                              guest: { push_protected_branch: false, merge_into_protected_branch: false },
                                                              reporter: { push_protected_branch: false, merge_into_protected_branch: false }))
        end

        context "when a specific user is allowed to push & merge into the #{protected_branch_type} protected branch" do
          let(:protected_branch) { build(:protected_branch, authorize_user_to_push: user, authorize_user_to_merge: user, name: protected_branch_name, project: project) }

          before do
            create(:merge_request, source_project: project, source_branch: unprotected_branch, target_branch: 'feature', state: 'locked', in_progress_merge_commit_sha: merge_into_protected_branch)
          end

          run_permission_checks(permissions_matrix.deep_merge(developer: { push_protected_branch: true, push_all: true, merge_into_protected_branch: true },
                                                              guest: { push_protected_branch: false, merge_into_protected_branch: false },
                                                              reporter: { push_protected_branch: false, merge_into_protected_branch: false }))
        end
      end

      context "group-specific access control" do
        let(:user) { create(:user) }
        let(:group) { create(:group) }

        before do
          group.add_maintainer(user)
        end

        context "when a specific group is allowed to push into the #{protected_branch_type} protected branch" do
          let(:protected_branch) { build(:protected_branch, authorize_group_to_push: group, name: protected_branch_name, project: project) }

          permissions = permissions_matrix.except(:admin).deep_merge(developer: { push_protected_branch: true, push_all: true, merge_into_protected_branch: true },
                                                                     guest: { push_protected_branch: false, merge_into_protected_branch: false },
                                                                     reporter: { push_protected_branch: false, merge_into_protected_branch: false })

          run_group_permission_checks(permissions)
        end

        context "when a specific group is allowed to merge into the #{protected_branch_type} protected branch" do
          let(:protected_branch) { build(:protected_branch, authorize_group_to_merge: group, name: protected_branch_name, project: project) }

          before do
            create(:merge_request, source_project: project, source_branch: unprotected_branch, target_branch: 'feature', state: 'locked', in_progress_merge_commit_sha: merge_into_protected_branch)
          end

          permissions = permissions_matrix.except(:admin).deep_merge(maintainer: { push_protected_branch: false, push_all: false, merge_into_protected_branch: true },
                                                                     developer: { push_protected_branch: false, push_all: false, merge_into_protected_branch: true },
                                                                     guest: { push_protected_branch: false, merge_into_protected_branch: false },
                                                                     reporter: { push_protected_branch: false, merge_into_protected_branch: false })

          run_group_permission_checks(permissions)
        end

        context "when a specific group is allowed to push & merge into the #{protected_branch_type} protected branch" do
          let(:protected_branch) { build(:protected_branch, authorize_group_to_push: group, authorize_group_to_merge: group, name: protected_branch_name, project: project) }

          before do
            create(:merge_request, source_project: project, source_branch: unprotected_branch, target_branch: 'feature', state: 'locked', in_progress_merge_commit_sha: merge_into_protected_branch)
          end

          permissions = permissions_matrix.except(:admin).deep_merge(developer: { push_protected_branch: true, push_all: true, merge_into_protected_branch: true },
                                                                     guest: { push_protected_branch: false, merge_into_protected_branch: false },
                                                                     reporter: { push_protected_branch: false, merge_into_protected_branch: false })

          run_group_permission_checks(permissions)
        end
      end
    end
  end

  describe '#check_smartcard_access!' do
    before do
      stub_licensed_features(smartcard_auth: true)
      stub_smartcard_setting(enabled: true, required_for_git_access: true)

      project.add_developer(user)
    end

    context 'user with a smartcard session', :clean_gitlab_redis_shared_state do
      let(:session_id) { '42' }
      let(:stored_session) do
        { 'smartcard_signins' => { 'last_signin_at' => 5.minutes.ago } }
      end

      before do
        Gitlab::Redis::SharedState.with do |redis|
          redis.set("session:gitlab:#{session_id}", Marshal.dump(stored_session))
          redis.sadd("session:lookup:user:gitlab:#{user.id}", [session_id])
        end
      end

      it 'allows pull changes' do
        expect { pull_changes }.not_to raise_error
      end

      it 'allows push changes' do
        expect { push_changes }.not_to raise_error
      end
    end

    context 'user without a smartcard session' do
      it 'does not allow pull changes' do
        expect { pull_changes }.to raise_error(Gitlab::GitAccess::UnauthorizedError)
      end

      it 'does not allow push changes' do
        expect { push_changes }.to raise_error(Gitlab::GitAccess::UnauthorizedError)
      end
    end

    context 'with the setting off' do
      before do
        stub_smartcard_setting(required_for_git_access: false)
      end

      it 'allows pull changes' do
        expect { pull_changes }.not_to raise_error
      end

      it 'allows push changes' do
        expect { push_changes }.not_to raise_error
      end
    end
  end

  private

  def access
    described_class.new(
      actor,
      project,
      protocol,
      authentication_abilities: authentication_abilities,
      namespace_path: namespace_path,
      project_path: project_path,
      redirected_path: redirected_path
    )
  end

  def push_changes(changes = '_any')
    access.check('git-receive-pack', changes)
  end

  def pull_changes(changes = '_any')
    access.check('git-upload-pack', changes)
  end

  def raise_unauthorized(message)
    raise_error(Gitlab::GitAccess::UnauthorizedError, message)
  end
end
