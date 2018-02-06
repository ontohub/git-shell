# frozen_string_literal: true

require 'json'
require 'rest-client'
require 'git-shell/errors'

module GitShell
  # Calls the backend for authorization.
  class AuthorizationCall
    attr_reader :public_key_id, :repository_slug

    def initialize(public_key_id, repository_slug)
      @public_key_id = public_key_id
      @repository_slug = repository_slug
    end

    def call
      return @authorization unless @authorization.nil?
      fetch_authorization_data
    end

    def pull?
      @authorization.is_a?(Hash) && !!@authorization[:pull]
    end

    def push?
      @authorization.is_a?(Hash) && !!@authorization[:push]
    end

    protected

    def fetch_authorization_data
      response = run_query
      response_data = JSON.parse(response).dig('data', 'gitAuthorization')
      if %w(pull push).any? { |field| response_data&.dig(field).nil? }
        raise BackendCallError
      end
      @authorization =
        {pull: response_data.dig('pull'), push: response_data.dig('push')}
    end

    # rubocop:disable Metrics/MethodLength
    def run_query
      # rubocop:enable Metrics/MethodLength
      operation_name = 'GitAuthorization'
      query = <<~QUERY
        query #{operation_name}($keyId: Int!, $repositoryId: ID!) {
          pull: gitAuthorization(keyId: $keyId, repositoryId: $repositoryId, action: pull)
          push: gitAuthorization(keyId: $keyId, repositoryId: $repositoryId, action: push)
        }
      QUERY
      variables = {
        keyId: public_key_id,
        repositoryId: repository_slug,
      }
      BackendCall.new(operation_name, query, variables).call
    end
  end
end
