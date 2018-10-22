require_relative 'spec_helper'
require 'rack/component'
require 'benchmark/ips'
require 'tilt'

Benchmark.ips do |bm|
  property = 'hello'
  struct = Struct.new(:property).new('hello')
  TEMPLATE = IO.read("#{__dir__}/fixtures/template.erb")
  tilt = Tilt['erb'].new { TEMPLATE }

  Comp = Class.new(Rack::Component) do
    def property() 'hello' end
    def render() TEMPLATE end
  end

  FastComp = Class.new(Rack::Component::Memoized) do
    def property() 'hello' end
    def render() TEMPLATE end
  end

  bm.report('Ruby stdlib ERB') do
    ERB.new(TEMPLATE).result(binding)
  end

  bm.report('Tilt (cached)') do
    tilt.render(struct)
  end

  bm.report('Component') do
    Comp.new.to_s
  end

  bm.report('Component::Memoized') do
    FastComp.new.to_s
  end
end
