# frozen_string_literal: true

require 'git-shell/application'

module GitShell
  # The Schema class to validate the Settings against
  class SettingsSchema < Dry::Validation::Schema
    configure do |config|
      config.messages_file = GitShell::Application.root.join(
        'config/settings_validation_errors.yml'
      )
    end

    def uri_has_scheme?(list, value)
      Array(list).include?(URI(value).scheme)
    end

    def uri_is_absolute?(value)
      URI(value).absolute?
    end

    def uri_has_no_path?(value)
      URI(value).path.empty?
    end

    def uri_has_no_query?(value)
      URI(value).query.nil?
    end

    def uri_has_no_fragment?(value)
      URI(value).fragment.nil?
    end

    def uri_has_no_userinfo?(value)
      URI(value).userinfo.nil?
    end

    def directory?(value)
      File.directory?(value)
    end

    define! do
      required(:backend).schema do
        required(:api_key).filled { str? }
        required(:url).filled(:str?,
                              :uri_is_absolute?,
                              :uri_has_no_path?,
                              :uri_has_no_query?,
                              :uri_has_no_fragment?,
                              :uri_has_no_userinfo?,
                              uri_has_scheme?: %w(http https))
      end

      required(:repository_root).filled { directory? }
    end
  end
end
