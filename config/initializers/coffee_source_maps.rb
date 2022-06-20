Rails.application.config.include_coffeescript_source_maps=false

if Rails.env.development? and Rails.application.config.include_coffeescript_source_maps
  require "base64"

  module Sprockets
    module CoffeeScriptProcessor
      DEFAULT_OPTIONS = { "sourceMap" => true }

      def self.call(input)
        data = input[:data]
        input[:cache].fetch([self.cache_key, data]) do
          result = Autoload::CoffeeScript.compile(data, DEFAULT_OPTIONS)

          source_map = result['v3SourceMap']
          parsed_source_map = MultiJson.decode(source_map)
          parsed_source_map['sources'] = [File.basename(input[:filename])]
          parsed_source_map['sourcesContent'] = [data]

          result['js'] + "\n//# sourceMappingURL=data:application/json;base64," + Base64.strict_encode64(MultiJson.encode(parsed_source_map))
        end
      end
    end
  end
end
