# frozen_string_literal: true

require_relative 'support/simplecov'

require 'factory_bot_rails'
require 'fuubar'
require 'rspec'

require 'git-shell'

Dir[File.expand_path('../../spec/support/**/*.rb', __FILE__)].each do |f|
  require f
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.disable_monkey_patching!

  config.default_formatter = 'doc' if config.files_to_run.one?

  # Print the 10 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  # config.profile_examples = 10

  config.order = :random

  config.fuubar_progress_bar_options = {format: '[%B] %c/%C',
                                        progress_mark: '#',
                                        remainder_mark: '-'}

  # Configure ruby to use the RSpec seed for randomization
  srand config.seed
end
