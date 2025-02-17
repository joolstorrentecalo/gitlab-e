# frozen_string_literal: true

require 'spec_helper'

describe Elastic::Latest::GitInstanceProxy do
  let(:project) { create(:project, :repository) }
  let(:included_class) { Elastic::Latest::RepositoryInstanceProxy }

  subject { included_class.new(project.repository) }

  describe '.methods_for_all_write_targets' do
    it 'contains extra method' do
      expect(included_class.methods_for_all_write_targets).to contain_exactly(
        *Elastic::Latest::ApplicationInstanceProxy.methods_for_all_write_targets,
        :delete_index_for_commits_and_blobs
      )
    end
  end

  describe '#es_parent' do
    it 'contains project id' do
      expect(subject.es_parent).to eq("project_#{project.id}")
    end
  end

  describe '#elastic_search' do
    let(:params) do
      {
        type: :fake_type,
        page: 2,
        per: 30,
        options: { foo: :bar }
      }
    end

    it 'provides repository_id if not provided' do
      expected_params = params.deep_dup
      expected_params[:options][:repository_id] = project.id

      expect(subject.class).to receive(:elastic_search).with('foo', expected_params)

      subject.elastic_search('foo', params)
    end

    it 'uses provided repository_id' do
      params[:options][:repository_id] = 42

      expect(subject.class).to receive(:elastic_search).with('foo', params)

      subject.elastic_search('foo', params)
    end
  end

  describe '#delete_index_for_commits_and_blobs' do
    let(:write_targets) { [double(:write_target_1), double(:write_target_2)] }
    let(:read_target) { double(:read_target) }

    before do
      project.repository.__elasticsearch__.tap do |proxy|
        allow(proxy).to receive(:elastic_writing_targets).and_return(write_targets)
        allow(proxy).to receive(:elastic_reading_target).and_return(read_target)
      end
    end

    it 'is forwarded to all write targets' do
      expect(read_target).not_to receive(:delete_index_for_commits_and_blobs)
      expect(write_targets).to all(
        receive(:delete_index_for_commits_and_blobs).and_return({ '_shards' => {} })
      )

      project.repository.delete_index_for_commits_and_blobs
    end
  end
end
