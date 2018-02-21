# frozen_string_literal: true

module GitShell
  class Error < ::StandardError; end
  class BackendCallError < Error; end
  class ConnectionError < Error; end
end
