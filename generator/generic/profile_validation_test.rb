# frozen_string_literal: true

module Inferno
  module Generator
    module ProfileValidationTest
      def create_profile_validation_test(metadata)
        profile_validation_test = {
          tests_that: "Server returns #{metadata.resource_type} resource that matches the #{metadata.title} profile",
          key: :resource_validate_profile,
          link: '',
          description: "This test will validate that the #{metadata.resource_type} resource returned from the server matches the #{metadata.title} profile."
        }
        profile_validation_test[:test_code] = %(
            skip 'No resource found from Read test' unless @resource_found.present?
            test_resource_against_profile('#{metadata.resource_type}', @resource_found, '#{metadata.url}')
        )
        metadata.add_test(profile_validation_test)
      end
    end
  end
end
