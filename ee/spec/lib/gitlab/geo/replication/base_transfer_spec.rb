# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Geo::Replication::BaseTransfer do
  include ::EE::GeoHelpers

  set(:primary_node) { create(:geo_node, :primary) }
  set(:secondary_node) { create(:geo_node) }

  describe '#can_transfer?' do
    subject do
      described_class.new(file_type: :avatar, file_id: 1, filename: Tempfile.new,
                          expected_checksum: nil, request_data: nil)
    end

    before do
      stub_current_geo_node(secondary_node)
    end

    context 'when not a primary node' do
      it 'returns false when not a secondary node' do
        expect(Gitlab::Geo).to receive(:secondary?) { false }

        expect(subject.can_transfer?).to be_falsey
      end
    end

    context 'when no primary node exists' do
      it 'returns false' do
        expect(Gitlab::Geo).to receive(:primary_node) { nil }

        expect(subject.can_transfer?).to be_falsey
      end
    end

    context 'when destination filename is a directory' do
      it 'returns false' do
        subject = described_class.new(file_type: :avatar, file_id: 1, filename: Dir::Tmpname.tmpdir,
                                      expected_checksum: nil, request_data: nil)

        expect(subject.can_transfer?).to be_falsey
      end
    end

    context 'when no filename is informed' do
      it 'returns true' do
        subject = described_class.new(file_type: :avatar, file_id: 1,
                                      expected_checksum: nil, request_data: nil)

        expect(subject.can_transfer?).to be_truthy
      end
    end

    it 'returns true when is a secondary, a primary exists and filename doesnt point to an existing directory' do
      expect(subject.can_transfer?).to be_truthy
    end
  end
end
