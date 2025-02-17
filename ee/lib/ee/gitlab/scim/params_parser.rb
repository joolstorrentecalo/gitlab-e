# frozen_string_literal: true

module EE
  module Gitlab
    module Scim
      class ParamsParser
        OPERATIONS_OPERATORS = %w[Replace Add].freeze

        def initialize(params)
          @params = params.with_indifferent_access
          @hash = {}
        end

        def deprovision_user?
          update_params[:active] == false
        end

        def post_params
          @post_params ||= process_post_params
        end

        def update_params
          @update_params ||= process_operations
        end

        def filter_params
          @filter_params ||= filter_parser.params
        end

        def filter_operator
          filter_parser.operator.to_sym if filter_parser.valid?
        end

        private

        def filter_parser
          @filter_parser ||= FilterParser.new(@params[:filter])
        end

        def process_operations
          @params[:Operations].each_with_object({}) do |operation, hash|
            next unless OPERATIONS_OPERATORS.include?(operation[:op])

            hash.merge!(AttributeTransform.new(operation[:path]).map_to(operation[:value]))
          end
        end

        def process_post_params
          overwrites = { email: parse_emails, name: parse_name }.compact

          # compact can remove :active if the value for that is nil
          @params.except(overwrites.keys).compact.each_with_object({}) do |(param, value), hash|
            hash.merge!(AttributeTransform.new(param).map_to(value))
          end.merge(overwrites)
        end

        def parse_emails
          emails = @params[:emails]

          return unless emails

          email = emails.find { |email| email[:type] == 'work' || email[:primary] }
          email[:value] if email
        end

        def parse_name
          name = @params.delete(:name)

          return unless name

          formatted_name = name[:formatted]&.presence
          formatted_name ||= [name[:givenName], name[:familyName]].compact.join(' ')
          @hash[:name] = formatted_name
        end
      end
    end
  end
end
