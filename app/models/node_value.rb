class NodeValue < ApplicationRecord

  def self.new_value(h)
    return NodeValue.find(0) if h.nil? or h == { 'value' => nil }
    v2 = NodeValue.new
    h.each do |k, v|
      case k
      when 'source_id', 'docid', 'extra', 'play_head'
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
          v2.send "#{k}=", v.join(',')
        else
          v2.send "#{k}=", v
        end
      end
    end
    v2
  end

  def self.copy_from_nde_values
    NdeValue.find_in_batches do |b|
      b.each do |nd|
        node = NodeValue.where(id: nd.id).first_or_create
        [
          :source_id,
          :docid,
          :begi,
          :endi,
          :value,
          :text,
          :play_head,
          :begr,
          :endr
        ].each do |x|
          node.send "#{x}=", nd.send(x)
        end
        node.save!
      end
    end
    Node.find_in_batches do |b|
      b.each do |node|
        node.update(node_value_id: node.nde_value_id)
      end
    end
  end

  def tvalue
    ( value || docid )
  end

end
