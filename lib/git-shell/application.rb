# frozen_string_literal: true

require 'config'
require 'pathname'
require 'git-shell/authorization'

module GitShell
  # The Application class encapsulates some basic properties and the main entry
  # points.
  class Application
    ROOT = Pathname.new(File.expand_path('../../../', __FILE__)).freeze
    ENVIRONMENT = (ENV['GIT_SHELL_ENV'] || 'development').freeze

    class << self
      def root
        ROOT
      end

      def env
        return @env if @env

        @env = ENVIRONMENT.dup
        %w(test development production).each do |e|
          @env.define_singleton_method("#{e}?") { ENVIRONMENT == e }
        end
        @env
      end

      def boot
        # This cannot be required at the top of the file because that file
        # itself requires the git-shell/application.
        require 'git-shell/settings_schema'
        Config.schema = Dry::Validation::Schema(SettingsSchema)
        Config.env_parse_values = true
        setting_files = ::Config.setting_files(root.join('config'), env)
        ::Config.load_and_set_settings(setting_files)

        normalize_paths

        true
      end

      def execute(command, public_key_id)
        return unless Authorization.new(command, public_key_id).call
        Executor.new(command).call
      end

      protected

      def normalize_paths
        Settings.repository_root = root.join(Settings.repository_root)
      end
    end
  end
end
