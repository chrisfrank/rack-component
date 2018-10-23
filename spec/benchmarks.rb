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

  Comp = Class.new(Rack::Component) do
    def render
      %(#{props.key})
    end
  end

  FastComp = Class.new(Rack::Component::Memoized) do
    def render
      %(#{props.key})
    end
  end

  bm.report('Ruby stdlib ERB') do
    ERB.new(ERB_TEMPLATE).result(binding)
  end

  bm.report('Tilt (cached)') do
    TILT_TEMPLATE.render(@model)
  end

  bm.report('Component') do
    Comp.call @model
  end

  bm.report('Component::Memoized') do
    FastComp.call @model
  end
end
