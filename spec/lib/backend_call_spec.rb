# frozen_string_literal: true

RSpec.describe GitShell::BackendCall do
  before do
    GitShell::Application.boot
    allow(RestClient).to receive(:post).and_return(response_body)
  end

  let(:operation_name) { 'operation' }
  let(:query) { 'query' }
  let(:variables) do
    {'foo' => 'FOO',
     'bar' => [1, 'BAR']}
  end
  let(:response_body) { 'response' }

  subject { GitShell::BackendCall.new(operation_name, query, variables) }

  shared_examples 'make the correct call' do
    it 'calls the backend with an ApiKey' do
      expect(RestClient).
        to receive(:post).
        with("#{Settings.backend.url}/graphql",
             match(/query.*variables/),
             include('Authorization' => "ApiKey #{Settings.backend.api_key}"))
      subject.call
      # rubocop:disable Lint/HandleExceptions
    rescue GitShell::ConnectionError, GitShell::BackendCallError
      # rubocop:enable Lint/HandleExceptions
    end
  end

  shared_examples 'without error' do
    it 'does not raise an error' do
      expect { subject.call }.not_to raise_error
    end

    it 'has the correct result' do
      expect(subject.call).to eq(response_body)
    end
  end

  shared_examples 'with error' do
    it 'raises the correct error' do
      expect { subject.call }.to raise_error(GitShell::ConnectionError)
    end
  end

  context 'without an error' do
    include_examples 'make the correct call'
    include_examples 'without error'
  end

  context 'without a connection to the backend' do
    let(:response_body) do
      {'data' => {'gitAuthorization' => nil}}.to_json
    end

    before do
      allow(RestClient).to receive(:post) do
        raise Errno::ECONNREFUSED
      end
    end

    include_examples 'make the correct call'
    include_examples 'with error'
  end

  context 'with an error while fetching the data' do
    let(:response_body) do
      {'data' => {'gitAuthorization' => nil}}.to_json
    end

    before do
      allow(RestClient).to receive(:post) do
        raise RestClient::Exception
      end
    end

    include_examples 'make the correct call'
    include_examples 'with error'
  end
end
