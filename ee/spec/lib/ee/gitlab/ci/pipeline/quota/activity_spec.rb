# frozen_string_literal: true

require 'spec_helper'

describe EE::Gitlab::Ci::Pipeline::Quota::Activity do
  set(:namespace) { create(:namespace) }
  set(:project) { create(:project, namespace: namespace) }
  set(:gold_plan) { create(:gold_plan) }
  let(:plan_limits) { create(:plan_limits, plan: gold_plan) }
  let!(:subscription) { create(:gitlab_subscription, namespace: namespace, hosted_plan: gold_plan) }

  subject { described_class.new(namespace, project) }

  shared_context 'pipeline activity limit exceeded' do
    before do
      create(:ci_pipeline, project: project, status: 'created')
      create(:ci_pipeline, project: project, status: 'pending')
      create(:ci_pipeline, project: project, status: 'running')

      plan_limits.update(ci_active_pipelines: 1)
    end
  end

  shared_context 'pipeline activity limit not exceeded' do
    before do
      plan_limits.update!(ci_active_pipelines: 2)
    end
  end

  describe '#enabled?' do
    context 'when limit is enabled in plan' do
      before do
        plan_limits.update!(ci_active_pipelines: 10)
      end

      it 'is enabled' do
        expect(subject).to be_enabled
      end
    end

    context 'when limit is not enabled' do
      before do
        plan_limits.update!(ci_active_pipelines: 0)
      end

      it 'is not enabled' do
        expect(subject).not_to be_enabled
      end
    end

    context 'when limit does not exist' do
      before do
        allow(namespace).to receive(:actual_plan) { create(:default_plan) }
      end

      it 'is not enabled' do
        expect(subject).not_to be_enabled
      end
    end
  end

  describe '#exceeded?' do
    context 'when limit is exceeded' do
      include_context 'pipeline activity limit exceeded'

      it 'is exceeded' do
        expect(subject).to be_exceeded
      end
    end

    context 'when limit is not exceeded' do
      include_context 'pipeline activity limit not exceeded'

      it 'is not exceeded' do
        expect(subject).not_to be_exceeded
      end
    end
  end

  describe '#message' do
    context 'when limit is exceeded' do
      include_context 'pipeline activity limit exceeded'

      it 'returns info about pipeline activity limit exceeded' do
        expect(subject.message)
          .to eq "Active pipelines limit exceeded by 2 pipelines!"
      end
    end
  end
end
