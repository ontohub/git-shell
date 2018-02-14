# frozen_string_literal: true

RSpec.describe GitShell::SettingsSchema do
  subject { Dry::Validation.Schema(GitShell::SettingsSchema).call(settings) }
  let(:settings) do
    {backend: {api_key: 'API_KEY', url: 'http://example.com'},
     data_directory: '/path/to/backend/data'}
  end

  before do
    allow(File).to receive(:directory?).and_call_original
    allow(File).
      to receive(:directory?).with(settings[:data_directory]).and_return(true)
  end

  it 'passes' do
    expect(subject.errors).to be_empty
  end

  context 'fails if the' do
    context 'backend' do
      context 'url' do
        it 'is nil' do
          settings[:backend][:url] = nil
          expect(subject.errors).
            to include(backend: include(url: ['must be filled']))
        end

        it 'is not a string' do
          settings[:backend][:url] = 0
          expect(subject.errors).to include(backend: include(url: ['must be a string']))
        end

        it 'has a bad schema' do
          settings[:backend][:url] = 'gopher://example.com'
          expect(subject.errors).to include(
            backend: include(url: ['has an invalid scheme (only http, https are allowed)'])
          )
        end

        it 'has a path' do
          settings[:backend][:url] = 'http://example.com/some_path'
          expect(subject.errors).to include(backend: include(url: ['must not have a path']))
        end

        it 'has a query string' do
          settings[:backend][:url] = 'http://example.com?query_string'
          expect(subject.errors).
            to include(backend: include(url: ['must not have a query string']))
        end

        it 'has a fragment' do
          settings[:backend][:url] = 'http://example.com#fragment'
          expect(subject.errors).
            to include(backend: include(url: ['must not have a fragment']))
        end

        it 'contains user info' do
          settings[:backend][:url] = 'http://user:pass@example.com'
          expect(subject.errors).
            to include(backend: include(url: ['must not have user info']))
        end
      end

      context 'api_key' do
        it 'is nil' do
          settings[:backend][:api_key] = nil
          expect(subject.errors).
            to include(backend: include(api_key: ['must be filled']))
        end
      end
    end

    context 'data_directory' do
      before do
        allow(File).
          to receive(:directory?).
          with(settings[:data_directory]).
          and_return(false)
        allow(File).
          to receive(:exist?).
          with(settings[:data_directory]).
          and_return(true)
      end

      it 'is nil' do
        settings[:data_directory] = nil
        expect(subject.errors).
          to include(data_directory: ['must be filled'])
      end

      it 'is not a directory' do
        expect(subject.errors).to include(
          data_directory: ['is not a directory']
        )
      end
    end
  end
end
