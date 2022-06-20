class NdeValue < ActiveRecord::Base

  def self.new_value(h)
    return NdeValue.find(0) if h.nil? or h == { 'value' => nil }
    v2 = NdeValue.new
    h.each do |k, v|
      case k
      when 'docid', 'extra', 'label', 'display_selector', 'waveform', 'timestamps', 'wave_buffer_sample_rate', 'buffer_length', 'play_head'
        v2.send "#{k}=", v
      when 'beg', 'end'
        case v
        when Fixnum
          if h['play_head']
            v2.send "#{k}r=", v
          else
            v2.send "#{k}i=", v
          end
        when String
          v2.send "#{k}r=", v.to_f
        when BigDecimal, Float
          v2.send "#{k}r=", v
        end
      when 'value', 'text'
        if v.class == Array
          v2.send "b#{k}=", v.join(',')
        else
          v2.send "b#{k}=", v
        end
      end
    end
    v2
  end

end
