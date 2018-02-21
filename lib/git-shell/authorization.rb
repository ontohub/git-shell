# frozen_string_literal: true

require 'git-shell/authorization_call'

module GitShell
  # Contains all the authorization logic
  class Authorization
    ALLOWED_GIT_ACTIONS =
      %w(git-upload-pack git-receive-pack git-upload-archive).freeze
    NO_READ_ACCESS_MESSAGE =
      'The Repository has not been found or you are unauthorized to read it.'
    NO_WRITE_ACCESS_MESSAGE =
      'Unauthorized: You are unauthorized to write to this repository.'
    BAD_GIT_ACTION_MESSAGE = 'Unauthorized: Bad git action.'
    BAD_REPOSITORY_SLUG = 'Unauthorized: Bad repository name format.'
    BACKEND_NOT_REACHABLE = 'Error: Failed to check permissions.'

    attr_reader :git_command, :repository_slug, :public_key_id

    def initialize(command_array, public_key_id)
      @git_command = command_array[0]
      @repository_slug = command_array[1]
      @public_key_id = public_key_id
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    def call
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/CyclomaticComplexity
      return fail_with(BAD_GIT_ACTION_MESSAGE) unless git_command_valid?
      return fail_with(BAD_REPOSITORY_SLUG) unless slug_valid?
      auth = AuthorizationCall.new(public_key_id, repository_slug).call
      return fail_with(NO_READ_ACCESS_MESSAGE) unless auth[:pull]
      return true if read_only_command?
      return fail_with(NO_WRITE_ACCESS_MESSAGE) unless auth[:push]
      true
    rescue BackendCallError, ConnectionError
      return fail_with(BACKEND_NOT_REACHABLE)
    end

    protected

    def fail_with(message)
      Kernel.warn(message)
      false
    end

    def git_command_valid?
      ALLOWED_GIT_ACTIONS.include?(git_command)
    end

    def slug_valid?
      !!@repository_slug.match(%r{[a-z0-9_\-]+/[a-z0-9_\-]})
    end

    def read_only_command?
      %w(git-upload-pack git-upload-archive).include?(git_command)
    end
  end
end
