require_relative 'spec_helper'
require 'rack/component'
require 'benchmark/ips'
require 'erubi'
require 'tilt'
require 'erb'

Benchmark.ips do |bm|
  TILT_TEMPLATE = Tilt['erb'].new { '<%= [:key] %>' }
  ERB_TEMPLATE = '<%= @model[:key] %>'
  @model = { key: 1 }

  Fn = lambda do |env|
    env[:key]
  end

  SafeComp = Class.new(Rack::Component) do
    render { |env| "%{env[:key]}" }
  end

  RawComp = Class.new(Rack::Component) do
    render(:raw) { |env| "#{env[:key]}" }
  end

  bm.report('Ruby ERB') do
    ERB.new(ERB_TEMPLATE).result(binding)
  end

  bm.report('Tilt') do
    TILT_TEMPLATE.render(@model)
  end

  bm.report('Component [safe]') do
    SafeComp.call @model
  end

  bm.report('Component [raw]') do
    RawComp.call @model
  end
end
