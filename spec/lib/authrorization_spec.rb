# frozen_string_literal: true

RSpec.describe GitShell::Authorization do
  let(:authorization_call) { double(:authorization_call) }
  before do
    GitShell::Application.boot
    allow(Kernel).to receive(:warn)
    allow(GitShell::AuthorizationCall).
      to receive(:new).and_return(authorization_call)
    allow(authorization_call).
      to receive(:call).
      and_return({pull: pull_permission, push: push_permission})
  end

  let(:executable) { 'git-upload-pack' }
  let(:repository_slug) { 'ada/fixtures' }
  let(:command_array) { [executable, repository_slug] }
  let(:public_key_id) { 23 }
  let(:pull_permission) { true }
  let(:push_permission) { true }

  subject { GitShell::Authorization.new(command_array, public_key_id) }

  shared_examples 'unauthorized' do
    it 'access is correct' do
      expect(subject.call).to be(false)
    end

    it 'prints a warning if authorization failed' do
      subject.call
      expect(Kernel).to have_received(:warn)
    end
  end

  shared_examples 'permissions' do
    context 'permissions' do
      context 'granted for pull' do
        let(:pull_permission) { true }

        context 'granted for push' do
          let(:push_permission) { true }

          it 'is correct' do
            expect(subject.call).to eq(permitted_command)
          end

          it 'prints a warning if authorization failed' do
            unless permitted_command
              subject.call
              expect(Kernel).to have_received(:warn)
            end
          end
        end

        context 'denied for push' do
          let(:push_permission) { false }

          it 'is correct' do
            expect(subject.call).to eq(permitted_command && read_only_command)
          end

          it 'prints a warning if authorization failed' do
            unless permitted_command && read_only_command
              subject.call
              expect(Kernel).to have_received(:warn)
            end
          end
        end
      end

      context 'denied' do
        let(:pull_permission) { false }
        let(:push_permission) { false }
        include_examples 'unauthorized'
      end
    end
  end

  context 'commands' do
    context 'git-upload-pack' do
      let(:executable) { 'git-upload-pack' }
      let(:permitted_command) { true }
      let(:read_only_command) { true }
      include_examples 'permissions'
    end

    context 'git-receive-pack' do
      let(:executable) { 'git-receive-pack' }
      let(:permitted_command) { true }
      let(:read_only_command) { false }
      include_examples 'permissions'
    end

    context 'git-upload-archive' do
      let(:executable) { 'git-upload-archive' }
      let(:permitted_command) { true }
      let(:read_only_command) { true }
      include_examples 'permissions'
    end

    context 'other' do
      let(:executable) { 'ls' }
      let(:permitted_command) { false }
      let(:read_only_command) { true }
      include_examples 'permissions'
    end
  end

  context 'with an error' do
    context 'BackendCallError' do
      before do
        allow(authorization_call).to receive(:call) do
          raise GitShell::BackendCallError
        end
      end
      include_examples 'unauthorized'
    end

    context 'ConnectionError' do
      before do
        allow(authorization_call).to receive(:call) do
          raise GitShell::ConnectionError
        end
      end
      include_examples 'unauthorized'
    end
  end
end
