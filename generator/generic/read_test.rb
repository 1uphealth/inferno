# frozen_string_literal: true

module Inferno
  module Generator
    module ReadTest
      def create_read_test(metadata)
        read_test = {
          tests_that: "Server returns correct #{metadata.resource_type} resource from the #{metadata.resource_type} read interaction",
          key: :resource_read,
          link: '',
          description: "This test will attempt to Reference to #{metadata.resource_type} can be resolved and read."
        }
        read_test[:test_code] = %(
            resource_id = @instance.#{metadata.resource_type.underscore}_id
            @resource_found = validate_read_reply(FHIR::#{metadata.resource_type}.new(id: resource_id), FHIR::#{metadata.resource_type})
        )
        metadata.add_test(read_test)
      end
    end
  end
end
