require 'spec_helper'

RSpec.describe Rack::Component do
  describe 'compared to a lambda' do
    let(:fn) {
      lambda do |env, &child|
        <<~HTML
          <h1>Hello #{CGI.escapeHTML env[:name]}</h1>
          #{child&.call}
        HTML
      end
    }
    let(:comp) {
      Class.new(Rack::Component) do
        render do |env, &child|
          <<~HTML
            <h1>Hello #{h env[:name]}</h1>
            #{child&.call}
          HTML
        end
      end
    }

    it 'behaves identically without children' do
      props = { name: 'Chris' }
      expect(comp.call(props)).to eq(fn.call(props))
    end

    it 'behaves identically with children' do
      props = { name: 'Chris' }
      actual = comp.call(props) { 'child' }
      expected = fn.call(props) { 'child' }

      expect(actual).to eq(expected)
    end

    it 'escapes HTML via a helper method' do
      result = comp.call(name: '<h1>hi</h1>')
      expect(result).to include('&lt;h1&gt;hi&lt;/h1&gt;')
    end
  end

  describe 'with a block in the +render+ macro' do
    it 'supports required keywords' do
      @comp = Class.new(Rack::Component) do
        render { |name:| name }
      end

      expect(@comp.call(name: 'Jean Luc')).to eq('Jean Luc')
      expect { @comp.call }.to raise_error(ArgumentError)
    end

    it 'supports optional keywords' do
      @comp = Class.new(Rack::Component) do
        render { |name: 'Jean Luc'| name }
      end

      expect(@comp.call).to eq('Jean Luc')
      expect(@comp.call(name: 'Riker')).to eq('Riker')
    end

    it 'can set optional keywords with instance methods' do
      @comp = Class.new(Rack::Component) do
        render { |name:, dept: department| "#{name} - #{dept}" }
        def department
          'Staff'
        end
      end
      expect(@comp.call(name: 'La Forge')).to eq('La Forge - Staff')
    end

    it 'can ommit args altogether' do
      @comp = Class.new(Rack::Component) { render { 'Enterprise' } }
      expect(@comp.call).to eq('Enterprise')
    end

    it 'allows &block as the only arg' do
      @comp = Class.new(Rack::Component) do
        render { |&child| child.call }
      end
      expect(@comp.call { 'Hi' }).to eq('Hi')
    end

    it 'can mix keyword args with a block' do
      @comp = Class.new(Rack::Component) do
        render do |name:, dept: 'Engineering', **, &child|
          "#{name} - #{dept} - #{child&.call}"
        end
      end

      result = @comp.call(name: 'Barclay') { 'etc' }
      expect(result).to eq('Barclay - Engineering - etc')
    end
  end


  describe 'with a template in the +render+ macro' do
    let(:expected) { "<h1>Hi, Spock&lt;&gt;</h1>\n" }

    it 'renders ERB' do
      @comp = Class.new(Rack::Component) do
        render erb: <<~HTML
          <h1>Hi, <%= env[:name] %></h1>
        HTML
      end
      expect(@comp.call(name: 'Spock<>')).to eq(expected)
    end

    it 'renders haml' do
      @comp = Class.new(Rack::Component) do
        render haml: <<~'HAML'
          %h1 Hi, #{env[:name]}
        HAML
      end
      expect(@comp.call(name: 'Spock<>')).to eq(expected)
    end

     it 'renders the engine you specify' do
      @comp = Class.new(Rack::Component) do
        render engine: 'erb', template: <<~ERB
          <h1>Hi, <%= env[:name] %></h1>
        ERB
      end
      expect(@comp.call(name: 'Spock<>')).to eq(expected)
     end

     it 'passes template options along via an +opts+ key' do
       @comp = Class.new(Rack::Component) do
         render opts: { escape_html: false }, erb: "<%= env[:key] %>"
       end

       result = @comp.call(key: '<h1>Hi</h1>')
       expect(result).to eq('<h1>Hi</h1>')
     end

     it 'supports the +yield+ keyword' do
       @layout = Class.new(Rack::Component) do
         render erb: "<%== yield %>"
       end

       expect(@layout.call { 'Hi' }).to eq('Hi')
     end
  end

  it 'fearlessly overrides initialize' do
    @comp = Class.new(Rack::Component) do
      render { |_| @id }

      def initialize(id)
        @id = id
      end
    end
    expect(@comp.call(1)).to eq(1)
  end

  it 'renders json swimmingly' do
    require 'json'
    @comp = Class.new(Rack::Component) do
      render { |env| env.to_json }
    end

    @comp.call(captain: 'kirk').tap do |res|
      expect(JSON.parse(res).fetch('captain')).to eq('kirk')
    end
  end
end
