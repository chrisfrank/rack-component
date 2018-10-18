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
        <main>
          <%= children %>
        </main>
      )
    end
  end

  class Header < Rack::Component
    def render
      %(
        <header>
          <h1>The Header</h1>
          <%= children %>
        </header>
      )
    end
  end

  class Footer < Rack::Component
    def render
      %(<footer>The Footer</footer>)
    end
  end

  class PropsComponent < Rack::Component
    def render
      %(<%= props[:name] %>)
    end
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
