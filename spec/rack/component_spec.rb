require 'spec_helper'
require_relative '../fixtures/views'
require 'pry'

RSpec.describe Rack::Component do
  it 'has a version number' do
    expect(Rack::Component::VERSION).not_to be nil
  end

  it 'renders children by default' do
    Rack::Component.call { 'child node' }.tap do |res|
      expect(res).to eq('child node')
    end
  end

  it 'nests components' do
    Views::Layout.call { 'nested' }.tap do |res|
      expect(res).to include('nested')
    end
  end

  it 'can mix ERB and string interpolation' do
    Test = Class.new(Rack::Component) do
      def render
        %(
          #{Views::Header.call}
          <main>the content</main>
          <%= Views::Footer.call %>
        )
      end
    end
    Test.call.tap do |res|
      expect(res).to include('<header>')
      expect(res).to include('<footer>')
    end
  end

  it 'has access to props when rendering' do
    Views::PropsComponent.call(name: 'Chris').tap do |res|
      expect(res).to eq('Chris')
    end
  end

  it 'can render json' do
    Views::JSONComponent.call { 'hmmm' }.tap do |res|
      expect(JSON.parse(res).first.fetch('rank')).to eq('captain')
    end
  end
end
