require 'routing_filter/base'

module RoutingFilter
  class Country < Base
    @@include_default_country = true
    cattr_writer :include_default_country
    @@include_default_locale = true
    cattr_writer :include_default_locale

    class << self
      def include_default_country?
        @@include_default_country
      end

      def countrys
        @@countrys ||= Preference.select_all( :region_id ).collect{ |x| x[:code].downcase }.map(&:to_sym)
      end

      def countrys=(countrys)
        @@countrys = countrys.map(&:to_sym)
      end

      def countrys_pattern
        @@countrys_pattern ||= %r(^/(#{self.countrys.map { |l| Regexp.escape(l.to_s) }.join('|')})(?=/|$))
      end
      
      def include_default_locale?
        @@include_default_locale
      end

      def locales
        @@locales ||= Preference.select_all( :default_language_id ).collect{ |x| x[:code].downcase }.map(&:to_sym)
      end

      def locales=(locales)
        @@locales = locales.map(&:to_sym)
      end

      def locales_pattern
        @@locales_pattern ||= %r(^/(#{self.locales.map { |l| Regexp.escape(l.to_s) }.join('|')})(?=/|$))
      end
      
    end

    def around_recognize(path, env, &block)
      country = extract_country!(path)                 # remove the country from the beginning of the path
      locale = extract_locale!(path)
      returning yield do |params|                    # invoke the given block (calls more filters and finally routing)
        params[:country] = country if country           # set recognized country to the resulting params hash
        params[:locale] = locale if locale
      end
    end

    def around_generate(*args, &block)
      options = args.extract_options!
      country = options.delete(:country)
      locale  = options.delete(:locale)
      returning yield do |result|
        url = result.is_a?(Array) ? result.first : result
        prepend_locale!(url, locale) if locale
        prepend_country!(url, country) if country
      end
    end

    protected

      def extract_country!(path)
        path.sub! self.class.countrys_pattern, ''
        $1
      end
      
      def prepend_country!(url, country)
        url.sub!(%r(^(http.?://[^/]*)?(.*))) { "#{$1}/#{country}#{$2}" }
      end
      
      def extract_locale!(path)
        path.sub! self.class.locales_pattern, ''
        $1
      end
      
      def prepend_locale!(url, locale)
        url.sub!(%r(^(http.?://[^/]*)?(.*))) { "#{$1}/#{locale}#{$2}" }
      end
  end
end
