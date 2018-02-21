# frozen_string_literal: true

RSpec.describe GitShell::Executor do
  before do
    GitShell::Application.boot
    allow(Kernel).to receive(:exec)
  end

  let(:executable) { 'git-upload-pack' }
  let(:repository_slug) { 'ada/fixtures' }
  let(:input) { [executable, repository_slug] }
  subject { GitShell::Executor.new(input) }
  let(:full_repository_path) do
    GitShell::Application.repository_root.join("#{repository_slug}.git")
  end
  let(:command) { "#{executable} #{full_repository_path}" }

  context 'attributes' do
    it 'splits the executable' do
      expect(subject.executable).to eq(executable)
    end

    it 'has the full repository path' do
      expect(subject.repository_path).to eq(full_repository_path)
    end

    it 'has the correct command' do
      expect(subject.command).to eq(command)
    end
  end

  context 'execution' do
    it 'calls exec with the command' do
      subject.call
      expect(Kernel).to have_received(:exec).with(command)
    end
  end
end
