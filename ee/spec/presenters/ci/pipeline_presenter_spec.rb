# frozen_string_literal: true

require 'spec_helper'

describe Ci::PipelinePresenter do
  let_it_be(:project, reload: true) { create(:project) }
  let_it_be(:pipeline, reload: true) { create(:ci_pipeline, project: project) }

  subject(:presenter) do
    described_class.new(pipeline)
  end

  context '#failure_reason' do
    context 'when pipeline has failure reason' do
      it 'represents a failure reason sentence' do
        pipeline.failure_reason = :activity_limit_exceeded

        expect(presenter.failure_reason)
          .to eq 'Pipeline activity limit exceeded!'
      end
    end

    context 'when pipeline does not have failure reason' do
      it 'returns nil' do
        expect(presenter.failure_reason).to be_nil
      end
    end
  end
end
