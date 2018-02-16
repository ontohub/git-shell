# frozen_string_literal: true

RSpec.describe GitShell::AuthorizationCall do
  before do
    GitShell::Application.boot
    allow_any_instance_of(GitShell::BackendCall).
      to receive(:call).
      and_return(response_body)
    allow(GitShell::BackendCall).to receive(:new).and_call_original
  end

  let(:public_key_id) { 23 }
  let(:repository_slug) { 'ada/fixtures' }

  subject { GitShell::AuthorizationCall.new(public_key_id, repository_slug) }

  shared_examples 'make the correct call' do
    it 'passes the correct payload' do
      expect(GitShell::BackendCall).
        to receive(:new).
        with('GitAuthorization',
             # rubocop:disable Metrics/LineLength
             match(/pull: gitAuthorization.*action: pull.*\s*push: gitAuthorization.*action: push.*/),
             # rubocop:enable Metrics/LineLength
             keyId: public_key_id, repositoryId: repository_slug)
      subject.call
      # rubocop:disable Lint/HandleExceptions
    rescue GitShell::BackendCallError, GitShell::ConnectionError
      # rubocop:enable Lint/HandleExceptions
    end
  end

  shared_examples 'without error' do
    it 'does not raise an error' do
      expect { subject.call }.not_to raise_error
    end

    it 'has the correct result' do
      expect(subject.call).
        to eq(pull: expected_pull_result, push: expected_push_result)
    end

    it 'pull? is correct' do
      subject.call
      expect(subject.pull?).to be(expected_pull_result)
    end

    it 'push? is correct' do
      subject.call
      expect(subject.push?).to be(expected_push_result)
    end
  end

  shared_examples 'with error' do |error_klass|
    it 'raises the correct error' do
      expect { subject.call }.to raise_error(error_klass)
    end
  end

  context 'without access' do
    let(:expected_pull_result) { false }
    let(:expected_push_result) { false }
    let(:response_body) do
      {'data' =>
        {'pull' => expected_pull_result,
         'push' => expected_push_result}}.to_json
    end

    include_examples 'make the correct call'
    include_examples 'without error'
  end

  context 'with read access' do
    let(:expected_pull_result) { true }
    let(:expected_push_result) { false }
    let(:response_body) do
      {'data' =>
        {'pull' => expected_pull_result,
         'push' => expected_push_result}}.to_json
    end

    include_examples 'make the correct call'
    include_examples 'without error'
  end

  context 'with write access' do
    let(:expected_pull_result) { true }
    let(:expected_push_result) { true }
    let(:response_body) do
      {'data' =>
        {'pull' => expected_pull_result,
         'push' => expected_push_result}}.to_json
    end

    include_examples 'make the correct call'
    include_examples 'without error'
  end

  context 'without a connection to the backend' do
    let(:response_body) do
      {'data' => nil}.to_json
    end

    before do
      allow_any_instance_of(GitShell::BackendCall).to receive(:call) do
        raise GitShell::ConnectionError
      end
    end

    include_examples 'make the correct call'
    include_examples 'with error', GitShell::ConnectionError
  end

  context 'with an error while processing the response data' do
    let(:response_body) do
      {'data' => nil}.to_json
    end

    include_examples 'make the correct call'
    include_examples 'with error', GitShell::BackendCallError
  end
end
