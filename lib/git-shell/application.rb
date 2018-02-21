# frozen_string_literal: true

require 'config'
require 'open3'
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

      def repository_root
        Settings.data_directory.join('git')
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

      def execute(command_array, public_key_id)
        return unless Authorization.new(command_array, public_key_id).call
        repository_slug = command_array[1]
        Dir.chdir("#{repository_root.join(repository_slug)}.git") do
          Executor.new(command_array).call
        end
      end

      # If the exit status is zero, updating the ref is permitted. Otherwise,
      # the update is prevented.
      # In a later version, we could ask the backend if the branch is protected
      # and allow the update if it's not protected. Then, we need to change the
      # analysis behaviour and possibly remove all data of deleted commits.
      def update(_public_key_id, repository_slug, _updated_ref,
                 revision_before_update, revision_after_update)
        if forced_update?(repository_slug,
                          revision_before_update, revision_after_update)
          Kernel.warn("Force-pushing (`git push --force') is not permitted.")
          Kernel.exit(1)
        else
          Kernel.exit(0)
        end
      end

      # This notifies the backend about all actually updated refs.
      def post_receive(public_key_id, repository_slug, updated_refs)
        RefUpdateNotifier.new(public_key_id, repository_slug, updated_refs).call
      end

      protected

      def normalize_paths
        Settings.data_directory = root.join(Settings.data_directory)
      end

      def forced_update?(repository_slug,
                         revision_before_update, revision_after_update)
        Dir.chdir("#{repository_root.join(repository_slug)}.git") do
          # It is a forced update if `revision_before_update` is NOT an ancestor
          # of `revision_after_update`, i.e. if the exit status is NOT success.
          _, _, status =
            Open3.capture3('git', 'merge-base', '--is-ancestor',
                           revision_before_update, revision_after_update)
          !status.success?
        end
      end
    end
  end
end
