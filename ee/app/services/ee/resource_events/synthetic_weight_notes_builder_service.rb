# frozen_string_literal: true

# We store events about issue weight changes in a separate table,
# but we still want to display notes about weight changes
# as classic system notes in UI. This service generates "synthetic" notes for
# weight event changes.

module EE
  module ResourceEvents
    class SyntheticWeightNotesBuilderService < ::ResourceEvents::BaseSyntheticNotesBuilderService
      private

      def synthetic_notes
        weight_change_events.map do |event|
          WeightNote.from_event(event, resource: resource, resource_parent: resource_parent)
        end
      end

      def weight_change_events
        return [] unless resource.respond_to?(:resource_weight_events)

        events = resource.resource_weight_events.includes(user: :status) # rubocop: disable CodeReuse/ActiveRecord
        since_fetch_at(events)
      end
    end
  end
end
