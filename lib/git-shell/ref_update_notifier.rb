# frozen_string_literal: true

module GitShell
  # Notifies the backend about all updated refs.
  class RefUpdateNotifier
    attr_reader :repository_slug, :public_key_id, :updated_refs

    def initialize(public_key_id, repository_slug, updated_refs_string)
      @public_key_id = public_key_id
      @repository_slug = repository_slug
      @updated_refs = updated_refs_string.lines.map do |line|
        revision_before_update, revision_after_update, updated_ref =
          line.strip.split(' ')
        {ref: updated_ref,
         before: revision_before_update,
         after: revision_after_update}
      end
    end

    def call
      run_query
    end

    protected

    # rubocop:disable Metrics/MethodLength
    def run_query
      # rubocop:enable Metrics/MethodLength
      operation_name = 'UpdateRefs'
      query = <<~QUERY
        mutation UpdateRefs($keyId: Int!, $repositoryId: ID!, $updatedRefs: [UpdatedRef!]!) {
          updateRefs(keyId: $keyId, repositoryId: $repositoryId, updatedRefs: $updatedRefs)
        }
      QUERY
      variables = {
        keyId: public_key_id,
        repositoryId: repository_slug,
        updatedRefs: updated_refs,
      }
      BackendCall.new(operation_name, query, variables).call
    end
  end
end
