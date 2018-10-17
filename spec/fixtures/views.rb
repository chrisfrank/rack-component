require 'rack/component'

module Views
  class Layout < Rack::Component
    def pages
      %w[this that]
    end

    def render
      %(
        <h1>Welcome</h1>
        <nav>
        <% pages.each do |page| %>
          <a href="#<%= page %>"><%= page %></a>
        <% end %>
        </nav>
        <%= children %>
      )
    end
  end

  class Header < Rack::Component
    TEMPLATE = %(<header>The Header</header>).freeze
  end

  class Footer < Rack::Component
    TEMPLATE = %(<footer>The Footer</footer>).freeze
  end

  class PropsComponent < Rack::Component
    TEMPLATE = %(<%= props[:name] %>).freeze
  end

  class JSONComponent < Rack::Component
    require 'json'

    def data
      [{ name: 'kirk', rank: 'captain' }, { name: 'spock', rank: 'captain' }]
    end

    def render
      data.to_json
    end
  end
end
