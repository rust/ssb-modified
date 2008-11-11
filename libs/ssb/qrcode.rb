# qrcode.rb - generate QR code data
#
# Author:: MIZOGUCHI Coji <mizoguchi.coji at gmail.com>
# License:: Distribute under the same terms as Ruby
#
# $Id: qrcode.rb 2826 2007-12-07 17:57:53Z coji $
#
require 'qrcode/qrcode' if FileTest.readable?(File.join(SSB::CONFIG[:vendor_dir], 'qrcode/qrcode.rb'))

class Qrcode
  def initialize
    @path="#{SSB::CONFIG[:vendor_dir]}/qrcode/qrcode_data"

    @qrcode_error_correct="L"
    @qrcode_version=0

    @qrcode_structureappend_n=1
    @qrcode_structureappend_m=1
    @qrcode_structureappend_parity=0
    @qrcode_structureappend_originaldata=""
  end
end

module SSB
  class Qrcode
    def self.make_qrcode(str)
      saved_kcode = $KCODE
      $KCODE = ''
      q = ::Qrcode.new
      begin
        qrcode = ''
        qrcode = q.make_qrcode(str) if q.respond_to?('make_qrcode')
      ensure
        $KCODE = saved_kcode
        return qrcode
      end
    end
  end
end
