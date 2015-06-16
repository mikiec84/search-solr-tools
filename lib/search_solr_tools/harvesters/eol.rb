require_relative './ade'

module SearchSolrTools
  module Harvesters
    class Eol < ADE
      def initialize(env = 'development', die_on_failure = false)
        super env, 'EOL', die_on_failure
      end
    end
  end
end