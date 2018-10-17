require_relative 'spec_helper'
require 'rack/component'
require 'benchmark/ips'
require 'tilt'

Benchmark.ips do |bm|
  property = 'hello'
  struct = Struct.new(:property).new('hello')
  template = IO.read("#{__dir__}/fixtures/template.erb")
  tilt = Tilt['erb'].new { template }

  FastComponent = Class.new(Rack::Component) do
    TEMPLATE = template
    def property
      'hello'
    end
  end

  SlowComponent = Class.new(Rack::Component) do
    def property
      'hello'
    end

    def template
      template
    end
  end

  bm.report('Raw ERB') do
    ERB.new(template).result(binding)
  end

  bm.report('Tilt (naive)') do
    Tilt['erb'].new { template }.render(struct)
  end

  bm.report('Tilt (cached)') do
    tilt.render(struct)
  end

  bm.report('Rack::Component') do
    FastComponent.call
  end

  bm.report('Rack::Component (slow)') do
    SlowComponent.call
  end
end
