require 'spec_helper'
require_relative 'components'

RSpec.describe 'a sinatra example' do
  let(:app) do
    require 'sinatra/base'
    Class.new(Sinatra::Base) do
      get('/posts/:id') { Components::Post.call(id: params[:id]) }
    end
  end

  it('renders a post') do
    get('/posts/1') { |res| expect(res.status).to eq(200) }
  end
end
