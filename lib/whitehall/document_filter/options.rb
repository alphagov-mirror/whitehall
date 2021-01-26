module Whitehall
  module DocumentFilter
    class Options
      def initialize(options = {})
        @locale = options[:locale] || I18n.locale
      end
    end
  end
end
