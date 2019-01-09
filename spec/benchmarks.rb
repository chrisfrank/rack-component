require_relative 'spec_helper'
require 'rack/component'
require 'benchmark/ips'
require 'tilt'
require 'erubi'
require 'securerandom'
require 'erb'

Benchmark.ips do |bm|
  Model = Struct.new(:key)
  ERB_TEMPLATE = '<%= model.key %>'
  TILT_TEMPLATE = Tilt['erb'].new(escape_html: true) { ERB_TEMPLATE }
  model = Model.new(SecureRandom.uuid)

  Fn = lambda do |model:|
    model.key
  end

  MacroComp= Class.new(Rack::Component) do
    render { "<%= env[:model].key %>" }
  end

  RawComp= Class.new(Rack::Component) do
    def render
      env[:model].key
    end
  end

  bm.report('Ruby stdlib ERB') do
    ERB.new(ERB_TEMPLATE).result(binding)
  end

  bm.report('Tilt (cached)') do
    TILT_TEMPLATE.render(nil, model: model)
  end

  bm.report('Lambda') do
    Fn.call model: model
  end

  bm.report('Component [raw]') do
    RawComp.call model: model
  end

  bm.report('Component [macro]') do
    MacroComp.call model: model
  end
end
