module Rack
  class Component
    # These are a few refinements to the core classes to make rendering easier
    module Refinements
      refine Array do
        # Join arrays with line breaks, so that calling list.map(&:render)
        # results in usable HTML
        def to_s
          join("\n")
        end
      end
    end
  end
end
