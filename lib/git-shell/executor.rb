# frozen_string_literal: true

module GitShell
  # Executes a command on a repository
  class Executor
    attr_reader :command, :executable, :repository_path

    def initialize(command)
      parts = command.split(' ')
      @executable = parts[0]
      @repository_path = Settings.repository_root.join("#{parts[1]}.git")
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
