# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Geo::GitPushHttp, :geo, :use_clean_rails_memory_store_caching do
  include EE::GeoHelpers

  let(:gl_id) { 'user-1234' }
  let(:gl_repository) { 'project-77777' }
  let(:cache_key) { "#{described_class::CACHE_KEY_PREFIX}:#{gl_id}:#{gl_repository}" }

  set(:secondary) { create(:geo_node) }
  subject { described_class.new(gl_id, gl_repository) }

  describe '#cache_referrer_node' do
    context 'when geo_node_id is present' do
      context 'when geo_node_id is an integer' do
        it 'stores the ID in cache' do
          subject.cache_referrer_node(secondary.id)

          value = Rails.cache.read(cache_key)
          expect(value).to eq(secondary.id)
        end

        it 'stores the ID with an expiration' do
          Timecop.freeze do
            subject.cache_referrer_node(secondary.id)

            Timecop.travel(described_class::EXPIRES_IN + 20.seconds) do
              value = Rails.cache.read(cache_key)
              expect(value).to be_nil
            end
          end
        end
      end

      context 'when geo_node_id is not an integer' do
        it 'does not cache anything' do
          subject.cache_referrer_node('bad input')

          value = Rails.cache.read(cache_key)
          expect(value).to be_nil
        end
      end
    end

    context 'when geo_node_id is blank' do
      it 'does not cache anything' do
        subject.cache_referrer_node(' ')

        value = Rails.cache.read(cache_key)
        expect(value).to be_nil
      end
    end
  end

  describe '#fetch_referrer_node' do
    context 'when there is a cached ID' do
      it 'deletes the key' do
        Rails.cache.write(cache_key, secondary.id, expires_in: described_class::EXPIRES_IN)

        subject.fetch_referrer_node

        expect(subject.fetch_referrer_node).to be_nil
      end

      context 'when the GeoNode exists' do
        it 'returns the GeoNode with the cached ID' do
          Rails.cache.write(cache_key, secondary.id, expires_in: described_class::EXPIRES_IN)

          expect(subject.fetch_referrer_node).to eq(secondary)
        end
      end

      context 'when the GeoNode does not exist' do
        it 'returns nil' do
          Rails.cache.write(cache_key, 9999998, expires_in: described_class::EXPIRES_IN)

          expect(subject.fetch_referrer_node).to be_nil
        end
      end
    end

    context 'when there is no cached ID' do
      it 'returns nil' do
        expect(subject.fetch_referrer_node).to be_nil
      end
    end
  end
end
