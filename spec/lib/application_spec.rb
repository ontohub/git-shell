# frozen_string_literal: true

RSpec.describe GitShell::Application do
  let(:authorization) { double(:authorization) }
  let(:executor) { double(:executor) }
  let(:ref_update_notifier) { double(:ref_update_notifier) }
  let(:authorized) { false }

  before do
    allow(GitShell::Authorization).to receive(:new).and_return(authorization)
    allow(authorization).to receive(:call).and_return(authorized)
    allow(GitShell::Executor).to receive(:new).and_return(executor)
    allow(executor).to receive(:call)
    allow(GitShell::RefUpdateNotifier).
      to receive(:new).and_return(ref_update_notifier)
    allow(ref_update_notifier).to receive(:call)
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

    context 'update' do
      let(:public_key_id) { 1 }
      let(:repository_slug) { 'ada/fixtures' }
      let(:updated_ref) { 'branch1' }
      let(:revision_before_update) { '0' * 40 }
      let(:revision_after_update) { '1' * 40 }

      before do
        allow(Kernel).to receive(:exit)
        allow(Kernel).to receive(:warn)
        GitShell::Application.update(public_key_id,
                                     repository_slug,
                                     updated_ref,
                                     revision_before_update,
                                     revision_after_update,
                                     forced_update)
      end

      context 'forced update' do
        let(:forced_update) { true }

        it 'prints an error message' do
          expect(Kernel).to have_received(:warn).with(match(/not allowed/))
        end

        it 'exits unsuccessfully' do
          expect(Kernel).to have_received(:exit).with(1)
        end
      end

      context 'not forced update' do
        let(:forced_update) { false }

        it 'exits unsuccessfully' do
          expect(Kernel).to have_received(:exit).with(0)
        end
      end
    end

    context 'post_receive' do
      let(:public_key_id) { 1 }
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

      before do
        GitShell::Application.post_receive(public_key_id,
                                           repository_slug,
                                           updated_refs)
      end

      it 'calls the executor' do
        expect(ref_update_notifier).to have_received(:call)
      end
    end
  end
end
