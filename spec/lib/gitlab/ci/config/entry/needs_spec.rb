# frozen_string_literal: true

require 'spec_helper'

describe ::Gitlab::Ci::Config::Entry::Needs do
  subject(:needs) { described_class.new(config) }

  describe 'validations' do
    before do
      needs.compose!
    end

    context 'when entry config value is correct' do
      let(:config) { ['job_name'] }

      describe '#valid?' do
        it { is_expected.to be_valid }
      end
    end

    context 'when wrong needs type is used' do
      let(:config) { [123] }

      describe '#valid?' do
        it { is_expected.not_to be_valid }
      end

      describe '#errors' do
        it 'returns error about incorrect type' do
          error_message = Gitlab.ee? ? 'need has to be a string, symbol or hash' : 'need has to be a string or symbol'

          expect(needs.errors)
            .to include error_message
        end
      end
    end
  end

  describe '.compose!' do
    context 'when valid job entries composed' do
      let(:config) { %w[first_job_name second_job_name] }

      before do
        needs.compose!
      end

      describe '#value' do
        it 'returns key value' do
          expect(needs.value).to eq(pipeline: %w[first_job_name second_job_name])
        end
      end

      describe '#descendants' do
        it 'creates valid descendant nodes' do
          expect(needs.descendants.count).to eq 2
          expect(needs.descendants)
            .to all(be_an_instance_of(::Gitlab::Ci::Config::Entry::Need))
        end
      end
    end
  end
end
