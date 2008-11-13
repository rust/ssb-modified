# ssb.rb - SSB Application
#
# Author:: MIZOGUCHI Coji <mizoguchi.coji at gmail.com>
# License:: Distributes under the same terms as Ruby
#
# $Id: ssb.rb 18924 2008-09-06 15:31:12Z koshigoe $
#
require 'erb'
require 'cgi'
require 'net/http'
require 'nkf'
require 'ssb/ktai_spec'
require 'ssb/emoji'
require 'ssb/time_stamper'
require 'ssb/misc'
require 'ssb/request'
require 'ssb/qrcode'

module SSB
  class Application
    def initialize
      SSB::config
      @time_stamp = SSB::TimeStamper.new({
                                         :request_time => [:request_start, :request_finish],
                                         :proc_time    => [:request_finish, :proc_finish],
                                         :total_time   => [:request_start, :proc_finish],
                                         })
    end

    def log(request_method, query, user_agent, uid)
      open(File.join(SSB::CONFIG[:home_dir], 'logs', 'browser.log'), 'a+') do |out|
        out.puts [Time.now, request_method, query, user_agent, uid].join("\t")
      end
    end

    # Does this rely on side effects?
    def process_response(cgi_response, ssb_response)
      case
      when ssb_response.nil?
        ['response is nil', 'N/A']
      when ssb_response.instance_of?(String)
        string_response(cgi_response, ssb_response)
      when ['301', '302'].include?(ssb_response.code)
        redirect_response(cgi_response, ssb_response)
      else
        ok_response(cgi_response, ssb_response)
      end
    end

    def ok_response(cgi_response, ssb_response)
      raw_content_type = ssb_response.header['content-type']
      case
      when raw_content_type.nil?
        cgi_response.header['Content-Type'] = "text/plain; charset=utf-8"
      when raw_content_type.include?('text/')
        cgi_response.header['Content-Type'] = "text/html; charset=utf-8"
      when raw_content_type.include?('application/xhtml')
        cgi_response.header['Content-Type'] = "text/html; charset=utf-8"
      else
        cgi_response.header['Content-Type'] = raw_content_type
        cgi_response.body = ssb_response.body
        return
      end
      page = ssb_response.body.dup.untaint
      [page, CGI.escapeHTML(NKF::nkf('-w -x', page))]
    end

    def redirect_response(cgi_response, ssb_response)
      cgi_response.header['Content-Type'] = 'text/html; charset=utf-8'
      redirect = ssb_response.header['location'].to_s.dup.untaint
      page = %q|<html><head></head><body><p style="background-color: #f0f000; color: navy">[SSB]リダイレクトされました</p>|
      page << %Q|<p style="font-size:x-small">#{redirect}</p><a href="#{redirect}">リダイレクト先へ</a></body></html>|
      source = CGI.escapeHTML(page.dup)
      [page, source]
    end

    def string_response(cgi_response, ssb_response)
      cgi_response.header['Content-Type'] = 'text/html; charset=utf-8'
      [NKF.nkf('-w -x', ssb_response.dup.untaint), 'N/A']
    end

    def run(cgi_request, cgi_response)
      @time_stamp.stamp(:request_start)

      # リクエストの生成
      @ssb_uri = 'http://' + cgi_request.host + File.basename(cgi_request.script_name) + '/'
      @request = SSB::Request.build_request(cgi_request)

      # ログ
      log(@request.method, @request.uri, @request.term.get_useragent(true), @request.term[:uid])

      # リクエスト
      source = ''
      response = @request.execute

      # リクエスト終了
      @time_stamp.stamp(:request_finish)

      page,source = process_response(cgi_response, response)
      if cgi_response.body != ""
        # レスポンスをまんま返しちゃったときとかはもうここで終わり。
        return
      end

      output_template(@request.uri,
                      response,
                      @request.term,
                      page,
                      source,
                      cgi_response)
    end

    def output_template(request_uri, response, term, page, source, res)
      # レスポンスヘッダ
      response_header = {}
      response.each do |k,v|
        response_header[k] = v
      end unless response.nil?

      # filter: 元の文字コードで
      page = SSB::Application.filter_html(page, request_uri, term, response)

      # SJIS等からUTF-8へ
      page = NKF::nkf('-w -x', page)

      # タイトル
      page =~ /<title(?:\s[^>]*)?>([^<]+)<\/title\s*>/
      title = $1

      # qrcode
      qrcode = SSB::Qrcode.make_qrcode(request_uri.to_s)

      # 変換処理終了
      @time_stamp.stamp(:proc_finish)

      begin
        template = open(File.join(SSB::CONFIG[:template_dir], 'ssb.rhtml')).read.untaint
        erb = ERB.new(template)
        res.body = erb.result(binding)
      rescue => e
        res.body = e
      end
    end

    def self.filter_html(page, request_uri, term, response)
      # XML宣言をけす。IEのバグ対応
      page.gsub!(/^\s*<\?xml[^>]+?\?>/, '')

      # ホスト名までの解決(ssl対策)
      case request_uri.port
      when 80
        request_host = "http://" + request_uri.host
      when 443
        request_host = "https://" + request_uri.host
      when nil
        request_host = ""
      else
        request_host = "http://" + request_uri.host + ':' + request_uri.port.to_s
      end

      # form action と a href と img src のURLを書き換え
      page = page.gsub(/\s(action|href|src|data)\s*=\s*(?:(["'])((?:\\\2|(?!\2).)+?)\2|([^\s>]+))([^>]*)>/imn) { |s|
        begin
          attribute = $1.downcase
          value     = $3 || $4
          # href=""/href='' の場合の対策
          value     = value.gsub(/["|']/, "")
          case attribute
          when 'src', 'data', 'href'
            case value[0,1]
            when '#'
              %Q! #{attribute}="#{value}"#{$5} target="_top">!
            when '/'
              %Q! #{attribute}="./?ssb_q=#{WEBrick::HTTPUtils.escape_form((request_host + CGI.unescapeHTML(value)).to_s)}"#{$5} target="_top">!
            else
              %Q! #{attribute}="./?ssb_q=#{WEBrick::HTTPUtils.escape_form((request_uri + CGI.escape(CGI.unescapeHTML(value))).to_s)}"#{$5} target="_top">!
              unless value =~ /http/
                %Q! #{ attribute}="./?ssb_q=#{ WEBrick::HTTPUtils.escape_form((request_host + '/' + CGI.unescapeHTML(value)).to_s)}"#{$5} target="_top">!
              else
                %Q! #{ attribute}="./?ssb_q=#{ WEBrick::HTTPUtils.escape_form(((CGI.unescapeHTML(value))).to_s)}"#{$5} target="_top">!
              end
            end
          when 'action'
            %Q! #{attribute}="./" #{$5}><input type="hidden" name="ssb_q" value="#{(request_uri + value).to_s}" />!
          end
        rescue => err
          %Q! #{$1}=""!
        end
      }

      # xx-small/xx-large を手加減
      page.gsub!(/xx-(?=large|small)/im, '')
      # 絵文字を <img> に変換
      is_utf8 = response.respond_to?(:header) && (response.header['Content-Type'] =~ /utf-?8/i)
      Emoji::emoji_conv(term, page, is_utf8)
    end
  end
end
