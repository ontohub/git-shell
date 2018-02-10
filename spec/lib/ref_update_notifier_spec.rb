# frozen_string_literal: true

RSpec.describe GitShell::RefUpdateNotifier do
  before do
    GitShell::Application.boot
    allow_any_instance_of(GitShell::BackendCall).
      to receive(:call).
      and_return(response_body)
    allow(GitShell::BackendCall).to receive(:new).and_call_original
  end

  let(:public_key_id) { 23 }
  let(:repository_slug) { 'ada/fixtures' }
  let(:updated_refs_arg) do
    [{ref: 'branch1', before: '0' * 40, after: '1' * 40},
     {ref: 'branch2', before: '2' * 40, after: '3' * 40},
     {ref: 'branch3', before: '4' * 40, after: '5' * 40}]
  end
  let(:updated_refs) do
    updated_refs_arg.map do |ref|
      [ref[:before], ref[:after], ref[:ref]].join(' ')
    end.join("\n")
  end

  subject do
    GitShell::RefUpdateNotifier.new(public_key_id,
                                    repository_slug,
                                    updated_refs)
  end

  shared_examples 'make the correct call' do
    it 'passes the correct payload' do
      expect(GitShell::BackendCall).
        to receive(:new).
        with('UpdateRefs',
             match(/mutation updateRefs(.*)/),
             keyId: public_key_id,
             repositoryId: repository_slug,
             updatedRefs: updated_refs_arg)
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
      expect(subject.call).to eq(response_body)
    end
  end

  shared_examples 'with error' do |error_klass|
    it 'raises the correct error' do
      expect { subject.call }.to raise_error(error_klass)
    end
  end

  context 'without access' do
    let(:response_body) do
      {'data' => {'updateRefs' => true}}.to_json
    end

    include_examples 'make the correct call'
    include_examples 'without error'
  end

  context 'without a connection to the backend' do
    let(:response_body) do
      {'data' => {'updateRefs' => nil}}.to_json
    end

    before do
      allow_any_instance_of(GitShell::BackendCall).to receive(:call) do
        raise GitShell::ConnectionError
      end
    end

    include_examples 'make the correct call'
    include_examples 'with error', GitShell::ConnectionError
  end
end
