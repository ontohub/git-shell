# frozen_string_literal: true

RSpec.describe GitShell::Application do
  let(:authorization) { double(:authorization) }
  let(:executor) { double(:executor) }
  let(:authorized) { false }

  before do
    allow(GitShell::Authorization).to receive(:new).and_return(authorization)
    allow(authorization).to receive(:call).and_return(authorized)
    allow(GitShell::Executor).to receive(:new).and_return(executor)
    allow(executor).to receive(:call)
  end

  context 'before booting' do
    it 'has the correct root' do
      expect(GitShell::Application.root).
        to eq(Pathname.new(File.expand_path('../../..', __FILE__)))
    end

    it 'the environment string is set' do
      expect(GitShell::Application.env).to eq('test')
    end

    it 'the environment method test? is setup' do
      expect(GitShell::Application.env.test?).to be(true)
    end

    it 'the environment method development? is setup' do
      expect(GitShell::Application.env.development?).to be(false)
    end

    it 'the environment method production? is setup' do
      expect(GitShell::Application.env.production?).to be(false)
    end
  end

  context 'after booting' do
    before do
      GitShell::Application.boot
    end

    it 'has the settings' do
      expect(Settings.backend).not_to be(nil)
    end

    it 'has normalized paths' do
      expect(Settings.repository_root).to be_a(Pathname)
    end

    context 'execute' do
      let(:command) { %w(git-upload-pack ada/fixtures) }
      let(:public_key_id) { 1 }

      before do
        GitShell::Application.execute(command, public_key_id)
      end

      it 'calls the authorization' do
        expect(authorization).to have_received(:call)
      end

      context 'authorized' do
        let(:authorized) { true }

        it 'calls the executor' do
          expect(executor).to have_received(:call)
        end
      end

      context 'unauthorized' do
        let(:authorized) { false }

        it 'does not call the executor' do
          expect(executor).not_to have_received(:call)
        end
      end
    end
  end
end
