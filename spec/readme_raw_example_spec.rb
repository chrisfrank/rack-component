require 'spec_helper'
require_relative 'fixtures'

RSpec.describe 'examples from the README' do
  describe('A raw rack example') do
    let(:app) do
      class RawExample < Rack::Component
        def render
          [200, { 'Content-Type' => 'text/html' }, [body]]
        end

        def body
          Layout.(title: 'Hello, World') do
            PostFetcher.(id: 1) do |post|
              PostView.call(post)
            end
          end
        end
      end

      RawExample
    end

    it('works') { get('/?id=1') { |res| expect(res).to be_ok } }
  end
end
