# frozen_string_literal: true

module GitShell
  # Executes a command on a repository
  class Executor
    attr_reader :command, :executable, :repository_path

    def initialize(command_array)
      @executable = command_array[0]
      repository_slug = command_array[1]
      @repository_path =
        Application.repository_root.join("#{repository_slug}.git")
      @command = "#{executable} #{repository_path}"
    end

    def call
      execute(command)
    end

    protected

    def execute(cmd)
      Kernel.exec(cmd)
    end
  end
end
