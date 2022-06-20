# == Schema Information
#
# Table name: reports
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  content    :text(16777215)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  type       :string(255)
#

class Report

  # "type" attribute use for STI

  # attr_accessible :name, :content
  # serialize :content, Hash

  # scope :sorted, -> { order('updated_at DESC, id DESC') }
  # scope :most_recent, -> { where(:pending => false).limit(1).sorted }

  def previous
    Reports::Report.where("id != ? AND updated_at <= ? AND type = ?", self.id, self.updated_at, self.type).most_recent.first
  end

  def prep(name='')
    @tables = []
    @obj = { name: name, tables: @tables }
    self.content = @obj
  end

  def create_table(title='')
    @rows = []
    @tables << { title: title, rows: @rows }
  end

  def create_row(a)
    @rows << a
  end

  #overwrite this on the rare reports that are only auto_generated
  def self.auto_generated?
    false
  end

  def email_support
    group_name = "report_#{self.class.to_s.split("::")[1]}"
    group_users = Group.find_by_name(group_name).users

    group_users.each do |user|
      if user.current_email && self.name
        ReportMailer.new_report(user.current_email, self.name, Time.now.to_s)
      end
    end
  end

  def filename
    self.class.to_s.sub(/.+::/, '').underscore
  end

  def to_tsvx(n=nil)
    tables = content[:tables]
    if tables
      if n.class == Fixnum and n < tables.size
        tables = [ tables[n] ]
      end
      tables.map do |table|
        table[:rows].map do |row|
          row.join "\t"
        end.join("\n")
      end.join("\n")
    else
      'unknown report type'
    end
  end

  def to_tsv(n=nil)
    tables = [ @table ]
    if tables
      if n.class == Fixnum and n < tables.size
        tables = [ tables[n] ]
      end
      tables.map do |table|
        ([table[:header]]+table[:rows]).map do |row|
          row.join "\t"
        end.join("\n")
      end.join("\n")
    else
      'unknown report type'
    end
  end

  def query_hash
    {
      'select' => [],
      'from' => '',
      'join' => [],
      'where' => [],
      'order' => []
    }
  end

  def rows_helper(db, q)
    $sequel_rails.fetch(q).to_a.map(&:values).map { |x| x.map { |x| x.class == String ? x.force_encoding('UTF-8') : x } }
  end

  def join_string
    a = @nodes.map.with_index do |n, i|
      "join nodes n#{i} on n#{i}.parent_id = p.id and n#{i}.name = '#{n}'"
    end.join "\n    "
    b = @nodes.map.with_index do |n, i|
      "join node_values v#{i} on v#{i}.id = n#{i}.node_value_id"
    end.join "\n    "
    "#{a}\n#{b}"
  end

  def select_fields
    @fields.map { |x| "#{x[2]} #{x[1]}" }.join ",\n      "
  end
  
  def run
    nn = 20
    title = 'blah'
    rows = []
    $sequel_rails.fetch(query).each do |row|
      rows << @fields.map { |x| row[x[1]] }
    end
    header = @fields.map(&:first)
    @table = {
      title: title,
      header: header,
      rows: rows
    }
    @table
  end

  def query_string(h)
    "
    select
      #{select_fields}
    from kits
    join nodes p  on p.tree_id = kits.tree_id
    #{join_string}
    where
      kits.task_id = #{@task.id} and
      #@done_kits
      p.name = '#@listitem' and
      p.current = true
    #@order
    "
  end

  def query_string2(h)
    "
    select
      #{select_fields}
    from kits
    join tasks on tasks.id = kits.task_id
    join nodes p  on p.tree_id = kits.tree_id
    #{join_string}
    left join kit_values kv1 on kv1.kit_id = kits.id and kv1.key = 'country_code'
    left join kit_values kv2 on kv2.kit_id = kits.id and kv2.key = 'city'
    where
      kits.task_id = #{@task.id} and
      #@done_kits
      p.name = '#@listitem'
    #@order
    "
  end

end
