# frozen_string_literal: true

require 'spec_helper'

describe 'Repository index', :elastic do
  context 'when fresh master branch is first pushed, followed by another update, then indexed' do
    let(:project) { create(:project_empty_repo) }
    let(:user) { project.owner }

    before do
      stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
      ElasticIndexerWorker.new.perform("index", "Project", project.id, project.es_id)
    end

    it 'indexes initial push' do
      sha1 = project.repository.create_file(user, '12', '', message: '12', branch_name: 'master')
      project.repository.create_file(user, '23', '', message: '23', branch_name: 'master')

      Gitlab::Elastic::Indexer.new(project).run(sha1)
      Gitlab::Elastic::Helper.refresh_index

      expect(indexed_file_paths_for('12')).to include('12')
    end

    def indexed_file_paths_for(term)
      blobs = Repository.elastic_search(term, type: :blob)[:blobs][:results].response
      blobs.map do |blob|
        blob['_source']['blob']['path']
      end
    end
  end
end
