# frozen_string_literal: true

module EE
  module Gitlab
    module PathRegex
      extend ActiveSupport::Concern

      class_methods do
        def saml_callback_regex
          @saml_callback_regex ||= %r(\A\/groups\/(?<group>#{full_namespace_route_regex})\/\-\/saml\/callback\z).freeze
        end

        def container_image_regex
          @container_image_regex ||= %r{([\w\.-]+\/){0,1}[\w\.-]+}.freeze
        end
      end
    end
  end
end
