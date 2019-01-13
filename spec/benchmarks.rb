require_relative 'spec_helper'
require 'rack/component'
require 'benchmark/ips'
require 'tilt'
require 'erubi'
require 'erb'

Benchmark.ips do |bm|
  Model = Struct.new(:purpose)
  ERB_TEMPLATE = '<%= CGI.escapeHTML model.purpose %>'
  TILT_TEMPLATE = Tilt['erb'].new(escape_html: true) { '<%= model.purpose %>' }
  model = Model.new("<h1>To boldy go where no one has gone before</h1>")

  Fn = lambda { |env| CGI.escapeHTML env[:model].purpose }

  MacroComp = Class.new(Rack::Component) do
    render { |env| h env[:model].purpose }
  end

  RawComp = Class.new(Rack::Component) do
    def render
      h env[:model].purpose
    end
  end

  TemplateComp = Class.new(Rack::Component) do
    render erb: "<%= env[:model].purpose %>"
  end

  bm.report('stdlib ERB') do
    ERB.new(ERB_TEMPLATE).result(binding)
  end

  bm.report('Tilt ERB') do
    TILT_TEMPLATE.render(nil, model: model)
  end

  bm.report('Bare lambda') do
    Fn.call model: model
  end

  bm.report('RC [def render]') do
    RawComp.call model: model
  end

  bm.report('RC [render do]') do
    MacroComp.call model: model
  end

  bm.report('RC [render erb:]') do
    TemplateComp.call model: model
  end
end
