require_relative 'spec_helper'
require 'rack/component'
require 'benchmark/ips'
require 'tilt'
require 'securerandom'
require 'erb'

Benchmark.ips do |bm|
  Model = Struct.new(:key)
  TILT_TEMPLATE = Tilt['erb'].new { '<%= key %>' }
  ERB_TEMPLATE = '<%= @model.key %>'
  @model = Model.new(SecureRandom.uuid)

  Fn = lambda do |model|
    model.key
  end

  Comp = Class.new(Rack::Component) do
    render { |env| env.key }
  end

  bm.report('Ruby stdlib ERB') do
    ERB.new(ERB_TEMPLATE).result(binding)
  end

  bm.report('Tilt (cached)') do
    TILT_TEMPLATE.render(@model)
  end

  bm.report('Lambda') do
    Fn.call @model
  end
  bm.report('Component') do
    Comp.call @model
  end

  bm.report('Component [memoized]') do
    Comp.memoized @model
  end
end
