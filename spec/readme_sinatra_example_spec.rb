require 'spec_helper'
require_relative 'fixtures'

RSpec.describe 'a sinatra example' do
  let(:app) do
    require 'sinatra/base'

    class SinatraExample < Sinatra::Base
      get '/' do
        Layout.(title: 'Home') do
          %(
            <h1>Home</h1>
            <p>is where I want to be</p>
            <p>Pick me up and turn me round</p>
          )
        end
      end

      get '/posts/:id' do
        PostFetcher.(id: params[:id]) do |post|
          Layout.(title: post[:title]) do
            PostView.(post)
          end
        end
      end
    end

    SinatraExample
  end

  it('renders the home page') do
    get('/') { |res| expect(res.body).to include('Home') }
  end
  it('renders a post') do
    get('/posts/1') { |res| expect(res.body).to include('Test Post') }
  end
end
