# emoji.rb - emoji convert
#
# Author:: MIZOGUCHI Coji <mizoguchi.coji at gmail.com>
# License:: Distributes under the same terms as Ruby
#
# $Id: emoji.rb 16139 2008-07-23 12:59:54Z drry $
#
require 'yaml'

module SSB
  module Emoji
    SJIS_ONE_BYTE  = '[\x00-\x7F\xA1-\xDF]'
    SJIS_TWO_BYTES = '[\x81-\x9F\xE0-\xFC][\x40-\x7E\x80-\xFC]'
    SJIS_IMODE_PICTOGRAM = '\xF8[\x9F-\xFC]|\xF9[\x40-\x7E\x80-\xB0]|\xF9[\xB1-\xFC]'
    RE_IMODE_SJIS = Regexp.new("((#{SJIS_IMODE_PICTOGRAM})|(#{SJIS_ONE_BYTE}|#{SJIS_TWO_BYTES}))")

    @@ez_uni2_table = nil
    @@docomo_uni2_table = nil

    # TODO: speed up!
    def self.ez_uni2number(uni)
      if @@ez_uni2_table.nil?
        @@ez_uni2_table = YAML.load_file(File.join(SSB::CONFIG[:dat_dir], 'kddi-table.yaml'))
      end
      @@ez_uni2_table.each {|x|
        if x['unicode'] == uni
          return x['number']
        end
      }
      nil
    end

    def self.docomo_uni2sjis(uni)
      if @@docomo_uni2_table.nil?
        @@docomo_uni2_table = YAML.load_file(File.join(SSB::CONFIG[:dat_dir], 'docomo-table.yaml'))
      end
      @@docomo_uni2_table.each {|x|
        if x['unicode'] == uni
          return x['sjis']
        end
      }
      nil
    end

    def self.emoji_conv(term, html, is_utf8=false)
      case term.get_carrier
      when KtaiSpec::CARRIER_DOCOMO
        convert_docomo(html, is_utf8)
      when KtaiSpec::CARRIER_KDDI
        convert_kddi(html)
      when KtaiSpec::CARRIER_SOFTBANK
        convert_thirdforce(html)
      else
        html
      end
    end

    def self.convert_docomo(html, is_utf8)
      html.gsub!(RE_IMODE_SJIS) { docomo_sjis_binary($1, $2) }
      html.gsub!(/./) { |c| docomo_utf8_binary(c) } if is_utf8
      html.gsub!(/&#([0-9]+);/) { docomo_sjis_decimal($1) }
      html.gsub(/(&#x([0-9a-zA-Z]+);)/) { docomo_unicode_hex($1, $2) }
    end

    # SJIS Binary
    def self.docomo_sjis_binary(original, inside)
      unless inside.nil?
        sprintf '<img class="emoji" src="emoji/docomo/%X.gif" />', original.unpack('n')[0]
      else
        original
      end
    end

    # UNICODE 16進数値文字参照 (とりあえず拡張絵文字だけ)
    def self.docomo_unicode_hex(original, unicode)
      code =
        case hex = unicode.hex
        when 0xE63E..0xE69B
          # 4705
          hex + 4705
        when 0xE69C..0xE6DA, 0xE6AC..0xE6BA
          # 4772
          hex + 4772
        when 0xE6DB..0xE70A, 0xE70C..0xE757
          # 4773
          hex + 4773
        else
          original
        end
      if code.is_a?(Integer)
        '<img class="emoji" src="emoji/docomo/' + (code).to_s(16).upcase + '.gif" />'
      else
        code
      end
    end

    # SJIS 10進数値文字参照
    def self.docomo_sjis_decimal(code)
      '<img class="emoji" src="emoji/docomo/' + code.to_i.to_s(16).upcase + '.gif" />'
    end

    # UTF8 BINARY
    def self.docomo_utf8_binary(code)
      sjis = SSB::Emoji.docomo_uni2sjis("%X" % ((code.size < 3) ? [code.to_i] : code.unpack("U")[0]))
      sjis ? sprintf('<img class="emoji" src="emoji/docomo/%s.gif" />', sjis) : code
    end

    def self.convert_kddi(html)
      html.gsub!(/(&#x([0-9a-zA-Z]+);)/) { kddi_localsrc($1, $2) }
      html.gsub(/\slocalsrc\s*=\s*(?:(["'])((?:\\\1|(?!\1).)+?)\1|([^\s>]+))/im) {
        %Q{ class="emoji" src="emoji/kddi/#{'%03d' % ($2 || $3).to_i}.gif"}
      }
    end

    # KDDI localsrc
    def self.kddi_localsrc(original, code)
      number = SSB::Emoji.ez_uni2number(code)
      if number.nil?
        original
      else
        sprintf '<img class="emoji" src="emoji/kddi/%03d.gif" />', number
      end
    end

    def self.convert_thirdforce(html)
      html.gsub!(/(&#x([a-zA-Z0-9]{4});)/) { thirdforce_unicode_hex_cref($1, $2) }
      re_sb_emoji = Regexp.new('\x1B\$(..)\x0F', 0, 'n')
      html.gsub(re_sb_emoji) { thirdforce_emoji($1) }
    end

    def self.thirdforce_unicode_hex_cref(original, unicode)
      code = unicode.hex
      if (0xE001 <= code and code <= 0xE05A) or
         (0xE101 <= code and code <= 0xE15A) or
         (0xE201 <= code and code <= 0xE253) or
         (0xE255 <= code and code <= 0xE257) or
         (0xE301 <= code and code <= 0xE34D) or
         (0xE401 <= code and code <= 0xE44C) or
         (0xE501 <= code and code <= 0xE537)
        sprintf "<img class='emoji' src='emoji/softbank/%s.gif' />", unicode
      else
        original
      end
    end

    def self.thirdforce_emoji(emoji)
        page_map = {
          ?G => 1,
          ?E => 2,
          ?F => 3,
          ?O => 4,
          ?P => 5,
          ?Q => 6,
        }
        code = ( (0xE0 + page_map[emoji[0]] - 1 ) << 8) + (emoji[1] - ?! + 1)
        sprintf "<img class='emoji' src='emoji/softbank/%04X.gif' />" % code
    end
  end
end
