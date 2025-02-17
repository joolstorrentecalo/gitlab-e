# frozen_string_literal: true

require 'spec_helper'

describe DesignManagement::NewVersionWorker do
  describe '#perform' do
    let(:worker) { described_class.new }

    context 'the id is wrong or out-of-date' do
      let(:version_id) { -1 }

      it 'does not create system notes' do
        expect(SystemNoteService).not_to receive(:design_version_added)

        worker.perform(version_id)
      end

      it 'logs the reason for this failure' do
        expect(Sidekiq.logger).to receive(:warn)
          .with(an_instance_of(ActiveRecord::RecordNotFound))

        worker.perform(version_id)
      end
    end

    context 'the version id is valid' do
      set(:version) { create(:design_version, :committed, designs_count: 2) }

      it 'creates a system note' do
        expect { worker.perform(version.id) }.to change { Note.system.count }.by(1)
      end

      it 'does not log anything' do
        expect(Sidekiq.logger).not_to receive(:warn)

        worker.perform(version.id)
      end
    end

    context 'the version includes multiple types of action' do
      set(:version) do
        create(:design_version, :committed,
               created_designs: create_list(:design, 1),
               modified_designs: create_list(:design, 1))
      end

      it 'creates two system notes' do
        expect { worker.perform(version.id) }.to change { Note.system.count }.by(2)
      end

      it 'calls design_version_added' do
        expect(SystemNoteService).to receive(:design_version_added).with(version)

        worker.perform(version.id)
      end
    end
  end
end
