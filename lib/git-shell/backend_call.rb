# frozen_string_literal: true

module GitShell
  # Calls the GraphQL Backend
  class BackendCall
    attr_reader :operation_name, :query, :variables, :payload

    def initialize(operation_name, query, variables)
      @operation_name = operation_name
      @query = query
      @variables = variables
      @payload = {
        operationName: operation_name,
        query: query,
        variables: variables,
      }
    end

    def call
      RestClient.post("#{Settings.backend.url}/graphql",
                      payload.to_json,
                      content_type: :json,
                      accept: :json,
                      'Authorization' => "ApiKey #{Settings.backend.api_key}")
    rescue RestClient::Exception, Errno::ECONNREFUSED
      raise ConnectionError, 'Connection to the backend failed.'
    end
  end
end
