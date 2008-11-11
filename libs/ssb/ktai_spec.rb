# ktai_spec.rb - specifications of ktai terminals
#
# Author:: MIZOGUCHI Coji <mizoguchi.coji at gmail.com>
# License:: Distributes under the same terms as Ruby
#
# $Id: ktai_spec.rb 4750 2008-01-16 20:05:04Z takeru $
#
require 'uri'

module SSB
  class KtaiSpec
    include Enumerable

    unless defined?(CARRIER_DOCOMO)
      CARRIER_DOCOMO   = 'DoCoMo'
      CARRIER_KDDI     = 'KDDI'
      CARRIER_SOFTBANK = 'SoftBank'
      CARRIER_WILLCOM  = 'WILLCOM'
      CARRIER_PC       = 'PC'
    end

    def initialize(props)
      @props = Hash.new

      @props[:useragent] = ''
      @props[:uid] = ''
      @props[:hid] = ''
      @props[:icc] = ''
      @props[:exheader] = ''

      if props.class == Hash
        props.each do |key,value|
          unless value.nil?
            @props[key.to_sym] = value
          else
            @props[key.to_sym] = ''
          end
        end
      else
        @props[:useragent] = props.to_s
      end
    end

    # get property
    # 'hid' Hardware ID
    # 'icc' FOMA CARD NO
    # 'useragent' User-Agent
    # 'uid' Terminal UID
    def [](key)
      @props[key]
    end

    # set property
    def []=(key, value)
      @props[key] = value
    end

    # get user-agent by carrier, hid and icc
    def get_useragent(hid = false, no_flash = false)
      if get_carrier() != CARRIER_DOCOMO || hid == false || (not has_key?(:hid))
        return @props[:useragent]
      end

      ua = @props[:useragent].dup
      unless ua.to_s == ''
        if ua =~ /DoCoMo\/1.0/ # PDC
          ua.concat '/' + self['hid'] unless self['hid'].nil?
        else                    # FOMA
          param_start = ua.index('(')
          ua = ua[0, param_start] unless param_start.nil?

          ua.concat '(c100;TB'
          ua.concat ';' + self[:hid]
          ua.concat ';' + self[:icc] if has_key?(:icc)
          ua.concat ')'

          # ua.gsub!(/;TB/, ';TC') unless no_flash
        end
      end
      return ua
    end

    # carrier detection
    def get_carrier
      ua = @props[:useragent]
      if ua =~ /DoCoMo/
        CARRIER_DOCOMO
      elsif ua =~ /KDDI/
        CARRIER_KDDI
      elsif ua =~ /Vodafone/
        CARRIER_SOFTBANK
      elsif ua =~ /SoftBank/
        CARRIER_SOFTBANK
      elsif ua =~ /J-PHONE/
        CARRIER_SOFTBANK
      elsif ua =~ /UP.Browser/
        CARRIER_KDDI
      elsif ua =~ /WILLCOM/
        CARRIER_WILLCOM
      elsif ua =~ /DDIPOCKET/
        CARRIER_WILLCOM
      else
        CARRIER_PC
      end
    end

    # get transformed URL if exists UID and DoCoMo
    def get_transformed_uri(uri)
      return nil if uri.nil?
      uri = URI.parse(uri) unless uri.kind_of?(URI)

      return uri unless get_carrier == CARRIER_DOCOMO
      return uri unless has_key?(:uid)
      return uri if uri.query.nil?

      uri.query.gsub!(/uid=NULLGWDOCOMO/, "uid=#{self[:uid]}")
      uri
    end

    # suitable request header by carrier
    def get_request_header(hid = false)
      header = Hash.new

      case get_carrier()
      when CARRIER_KDDI
        header['X-UP-SUBNO'] = self[:uid]
      when CARRIER_SOFTBANK
        header['X-JPHONE-UID'] = self[:uid]
      end if has_key?(:uid)

      header['User-Agent'] = get_useragent(hid)

      @props[:exheader].split("\r\n").each do |field|
        key,value = field.split(':')
        unless key.nil? || value.nil?
          header[key.strip] = value.strip
        end
      end

      header
    end

    def size
      @props.size
    end
    alias length size

    def has_key?(key)
      @props.has_key?(key)
    end

    def each(&block)
      @props.each { |key, value| yield key, value }
    end

    def inspect
      '{' + @props.collect { |key,value| "#{key}=>#{value.inspect}" }.join(",") +'}'
    end
  end
end
