class SourcesController < ApplicationController

  include SourcesHelper

  skip_before_action :verify_authenticity_token, only: [ :create ]
  before_action :authenticate, except: [ :uget_public ]

  def get_ner
    raise
    response = Hash.new
    mongo = Mongo::Connection.new
    if params[:lang] == 'eng'
      LDCI::ner(params[:decode] ? URI.decode(params[:text]) : params[:text]).each do |k,v|
        namestring = mongo.db('projects')['kbp'].find_one( :_id => k )
        count = namestring ? namestring['count'] : nil
        response[k] = {'type' => v, 'count' => count}
      end
    end
    if params[:lang] == 'spa'
      doc = mongo.db('projects')['kbp'].find_one( :_id => params[:docid] )
      if doc
        doc['ner'].each do |arrayPair|
          namestring = mongo.db('projects')['kbp'].find_one( :_id => arrayPair[0] )
          count = namestring ? namestring['count'] : nil
          response[arrayPair[0]] = {'type' => arrayPair[1].downcase, 'count' => count}
        end
      end
    end
    respond_to do |format|
      format.js { render :json => response }
    end
  end

  def new
    @source = Source.new
    respond_to do |format|
      format.html do
        render partial: 'new'
      end
    end
  end

  def get_upload
    @source = Source.new
    @task_id = params[:task_id]
    @project = Project.find params[:project_id] if params[:project_id]
    @task = Task.find params[:task_id] if @task_id and @task_id.to_i > 0
    @data_set = DataSet.find params[:data_set_id] if params[:data_set_id]
    @researcher = Researcher.find params[:researcher_id] if params[:researcher_id]
    @partner = Partner.find params[:partner_id] if params[:partner_id]
    respond_to do |format|
      format.html do
        render partial: 'upload'
      end
      format.json do
        partial = params[:partial] || 'upload'
        html = render_to_string(:partial => partial)
        render json: { html: html }
      end
    end
  end

  def create
    source = Source.create!(nvparams)
    source.update(uid: source&.file&.blob.key) if source.uid.nil?
    source.update(user_id: current_user.id)
    # source = Source.last
    respond_to do |format|
      format.html do
        redirect_to root_path
      end
      format.json do
        render json: source
      end
    end
  end

  def get_download
    @source = Source.find params[:id]
    respond_to do |format|
      format.html do
        render partial: 'download'
      end
    end
  end

  def nvparams
    params.require(:source).permit(:uid, :file, :task_id)
  end

  def uget_public
    params[:level] = params[:level].to_i if params.has_key? :level
    if params[:uid] and params[:uid] =~ /^NYT_ENG_19940701.000\d\Z/
      respond_to do |format|
        format.html { render text: 'hi' }
        if params[:level] == 2
          json = {}
          Kit.where(task_id: 164).each do |kit|
            if kit.meta[:source_uid] == params[:uid]
              root = kit.tree.tree
              json[:text_extents] = root.find_by_css('Text')
              json[:coref] = root.coref.to_hash
              break
            end
          end
          format.json { render json: json }
        else
          format.json { render json: LDCI.uget(params.to_json).to_json }
        end
      end
    else
      respond_to do |format|
        format.html { render text: 'sorry' }
        format.json { render text: 'sorry' }
      end
    end
  end

  def uget1
      # raise LDCI::ConfigError, "No entry for :ugeti_http in ldci.config." unless LDCI::CONFIG[:services].key?(:ugeti_http)
      server, port = LDCI::CONFIG[:services][:ugeti_http].split(':')
      port = port.to_i
      uri = URI::HTTP.build(:host => server, :port => port, :path => "/sources/#{params['uid']}")
      response = Net::HTTP.start(server, port) do |http|
        request = Net::HTTP::Get.new(uri.request_uri)
        request.basic_auth 'admin', LDCI::CONFIG[:services][:ugeti_code]
        request["Accept"] = 'application/json'
        http.request(request)
      end
      obj = case response
      when Net::HTTPSuccess
        JSON.parse response.body
      when Net::HTTPNotFound
        nil
      else
        response.value # raise exception
      end
      obj['orig'].force_encoding 'UTF-8'
      obj['id'] = obj['uid']
      obj['docid'] = obj['uid']
      obj
  end

  def uget5
    if params[:dev]
      { string: File.read(params[:path]) }
    elsif params[:local]
      uget_text
    else
=begin
      h = {
        "transform"=>"true",
        "uid"=>"NYT_ENG_19940701.0001",
        "type"=>"document",
        "level"=>1,
        "line_char_limit"=>70
      }
      h['id'] = h['uid']
      h['string'] = open("https://ldc-developers.s3.amazonaws.com/#{h['uid']}.xml").read
      h
=end
      LDCI.uget(params, false)
    end
  end

  def uget3
    if params[:uid] and params[:uid] =~ /^sentence-(\d+)/
      obj = params.merge( { 'string' => Sentence.find($1).text, 'type' => 'document' } )
    else
      obj = uget5
      if obj['uid'] =~ /^m\./
        i = obj['string'].index('description')
        obj['hack'] = obj['string'][i..-1]
        obj['string'] = obj['string'][0...i]
      end
    end
    obj
  end

  def uget4(obj)
    line_limit = (params[:line_char_limit] || 70).to_i
    if obj['type'] == 'document'
      file = obj['string']
      file.force_encoding 'UTF-8'
      if params['task_id'].to_i == 593 and file[0..4] == '<?xml'
        i = file =~ /<DOC/i
        file = file[i..-1]
      end
      if params[:get_lines].to_i == 1
        obj = LDCI::Document.new(obj['uid'], file, params['transform'], 'normal', line_limit).get_hash
        obj.delete :orig
      elsif params[:get_lines].to_i == 2
        obj = LDCI::Document.new(obj['uid'], file, params['transform'], 'sentence', line_limit, params['segmenter']).get_hash
        obj.delete :orig
      else
        obj[:orig] = file
        obj[:id] = obj['uid']
        obj[:docid] = obj['uid']
        obj.delete ['string']
      end
    elsif obj['type'] == 'multi_post' && params[:get_lines].to_i == 2
      obj = LDCI::Document.new(obj['uid'], obj['orig'], params['transform'], 'sentence', line_limit, params['segmenter']).get_hash
      obj.delete :orig
    elsif obj['type'] == 'ltf'
      file = obj['string']
      file.force_encoding 'UTF-8'
      obj[:orig] = file
      obj[:id] = obj['uid']
      obj[:docid] = obj['uid']
      obj.delete 'string'
    end
    obj
  end

  def uget2
    params[:level] = params[:level].to_i if params.has_key? :level
    if params[:uid] == 'to_be'
      YAML.load File.read "to_be_#{params[:get_lines].to_i == 1 ? 'lines' : 'string'}.yaml"
    else
      obj = uget3
      raise ActiveRecord::RecordNotFound if obj.nil?
      uget4 obj
    end
  end

  def uget
    $stderr.puts params
    if params['uid'] and params['uid'][0..1] == 'IL' and LDCI::CONFIG[:services][:ugeti_task_ids].include?(params['task_id'])
      obj = uget1
    elsif params[:media]
      media
      return
    else
      obj = uget2
    end
    # raise obj.to_yaml if params['get_lines']
    # if params['get_lines']
    #   open( '/Users/jdwright/Downloads/temporaryugetsource2', 'w') { |f| f.puts obj.to_yaml }
    # else
    #   open( '/Users/jdwright/Downloads/temporaryugetsource', 'w') { |f| f.puts obj.to_yaml }
    # end
    # obj = YAML.load File.read '/Users/jdwright/Downloads/temporaryugetsource'
    # File.write '/Users/jdwright/Downloads/temporaryugetsource2', obj.to_yaml
    # obj = YAML.load File.read '/Users/jdwright/Downloads/temporaryugetsource2'
    respond_to do |format|
      format.html { render text: 'hi' }
      format.json do
        # if Rails.env.development?
        #   # x = UserDefinedObject.new
        #   # x.object = obj
        #   # x.save
        #   obj = YAML.load UserDefinedObject.last.object
        # end
        render json: obj
      end
    end
  end

  def get_text
    doc = get_source_text(params[:docid], params[:transform])
    respond_to { |format|
      format.js
      format.json { render :json => doc }
    }
  end

  def audio
    send_data( get_source_audio(params[:docid]), :type => 'audio/wav' )
  end

  def text
    text = Text.find params[:id]
    respond_to do |format|
      format.html do
        # send_data( text.text_string.text, type: 'text/plain' )
        send_data( 'try json', type: 'text/plain' )
      end
      format.json { render json: text.to_interchange(1) }
    end
  end

  def audio_full
    #data = File.exists?(response) ? File.read(response) : ''
    if params[:docid] =~ /^\d+\Z/
      p = ComputeProcess.find 3
      p.prepare_to_determine_file_path :lre14
      response = p.determine_file_path Audio.find params[:docid]
    else
      response = LDCI.uget( { :id => params[:docid], :type => 'audio', :path => true }.to_json )
    end
    send_file( response, :type => 'audio/wav' )
  end

  def media
    $stderr.puts 'media'
    $stderr.puts params
    media2 Source.find_by_uid(params[:uid]).path
  end

  def media3
    $stderr.puts 'media3'
    $stderr.puts params
    return unless params[:uid] == 'glg1.json'
    media2 Source.find_by_uid(params[:uid]).path
  end

  def cors
    headers['Access-Control-Allow-Origin'] = request.headers['Origin']
  end

  private

  def get_mime_type(x)
    'unknown'
  end

  def media2(fn)
    fn = File.exists?(fn) ? fn : nil # only returns existing files
    if fn
      type = case params[:type]
      when 'text'
        'text/plain'
      when 'audio'
        'audio/wav'
      when 'xml'
        'text/xml'
      when 'json'
        'application/json'
      else
        get_mime_type params[:uid].match(/\.\w+\Z/)[0]
      end
      if Rails.env.production?
        if params[:beg] and params[:end]
          raise 'unimplemented'
          b, e = params[:beg], params[:end]
          e = af.duration.to_s if e.to_f > af.duration
          c = "/home/rubyuser/trim #{fn} #{b} #{e}"
          logger.info c
          base = File.basename(fn).sub('.wav', "__#{b}__#{e}__.wav" )
          send_data(
            `#{c}`,
            :type => 'audio/wav',
            :disposition => "attachment; filename=#{base}"
          )
        else
          # send_file( fn, type: 'audio/wav' )
          base = File.basename(fn)
          send_data(
            File.read(fn),
            :type => type,
            # :disposition => "attachment; filename=#{base}"
            :disposition => "inline"
          )
        end
      # elsif params[:beg] and params[:end]
      #   base = File.basename fn
      #   send_data(
      #     `/Users/jdwright/Downloads/trim #{fn} #{params[:beg]} #{params[:end]}`,
      #     :type => 'audio/wav',
      #     :disposition => "attachment; filename=#{base}"
      #   )
      else
        # Assumes that our non-production environment uses a web server that
        # is not as smart as Apache and/or Phusion Passenger, e.g. webrick or
        # thin.
        #
        # If the request is a range request, manualy craft a range response.
        file = File.open(fn, 'rb')
        file_begin = 0
        file_size = file.size
        file_end = file_size - 1
        chunk_size = file_size
        if !request.headers["Range"]
          status_code = "200 OK"
        else
          status_code = "206 Partial Content"
          match = request.headers['range'].match(/bytes=(\d+)-(\d*)/)
          if match
            file_begin = match[1].to_i
            file_end = match[2].to_i if match[2] && !match[2].empty?
          end
          chunk_size = [file_end - file_begin + 1, 2 * 1024 * 1024].min
          file_end = file_begin + chunk_size - 1
          response.header["Content-Range"] = "bytes " + file_begin.to_s + "-" + file_end.to_s + "/" + file_size.to_s
        end
        response.header["Content-Length"] = chunk_size.to_s
        response.header["Last-Modified"] = file.mtime.strftime "%a, %d %b %Y %H:%M:%S %Z"
        file.seek file_begin
        send_data(
            file.read(chunk_size),
          :type => type,
          :disposition => 'inline',
          :status => status_code
        )
        file.close
      end
    else
      render nothing: true, status: 404
    end
  end

end

# encoding: utf-8
module LDCI

  class Document

    attr_reader :char_index, :line_index, :orig, :id, :type, :meta

    def initialize(docid, original_text, transform_flag=false, source_type='normal', line_char_limit=70, segmenter=nil)
      @id = docid
      @char_index = []
      @line_index = []
      @orig = original_text
      @line_char_limit = line_char_limit
      @meta = {}#used to extract any meta fields that exist within the document content
      transform(original_text, source_type, segmenter) if transform_flag and not original_text.empty?
    end

    def get_hash
      { :id => @id, :type => 'document', :orig => @orig, :char_index => @char_index, :line_index => @line_index,
        :meta => @meta, :docid => @id  }
    end



  #SENTENCE_SEGMENTER = LDCI::CONFIG[:sentence_segmenter]

  # why does this exist?  it doesn't do what I expected
  def convert_post_xml_offsets_to_global(string, id, b, e)
    #Nokogiri::XML(string).css("post[id=#{id}]")[0].text
    offset = string =~ /<post .*?id="#{id}"/
    [ b+offset, e+offset ]
  end

  ### xiaoyi ma: this function is not used by transform_default anymore, but
  ### it's still being used by other transform_ functions; Eventually, all transform_
  ### functions should be modified to not use calculate_line_char_limit
  ###
  #this function attempts to calculate the number of characters that can fit in a TextSource pane per line (70 is default)
  #without requiring horizontal scrolling, it counts the number of uppercase characters and then uses the following formula
  #line_char_limit = default_line_char_limit - 1/2*(default_line_char_limit * (uppercase_count/total_count))
  def calculate_line_char_limit(original_text)
    total_length = original_text.length
    return 70 if total_length == 0
    uppercase_characters = original_text.scan(/[A-Z]/).length
    percent_uppercase = uppercase_characters.to_f / total_length.to_f

    if original_text.match(/\p{Han}/)
      @line_char_limit /= 2
    else
      @line_char_limit = @line_char_limit - ((@line_char_limit.to_f * percent_uppercase).to_i / 2)
    end
  end

  def transform(original_text, source_type='normal', segmenter=nil)
    case source_type
    when 'OSC'
      transform_OSC(original_text)
    when 'CTS'
      transform_CTS(original_text)
    when 'chinese'
      transform_chinese original_text
    when 'sentence'
      transform_sentences(original_text, segmenter)
    else
      transform_default(original_text)
    end
  end

  #this function transforms a CTS document, hiding the necessary parts
  def transform_CTS(original_text)
    isMarkup = false#tracks whether we are inside markup or not
    calculate_line_char_limit original_text
    original_text << "\n" unless original_text[-1] == "\n"
    chars = []
    lines = [Array.new]
    original_text.split('').each_with_index do |c, i|

      #entering markup, set flag to skip until we find '>'
      if original_text[i..i+10].start_with?('<noise>') || original_text[i..i+10].start_with?('</noise>')
        isMarkup = true
      end

      if !isMarkup
        #if there is an existing line break before the character limit for a line, start a new line
        if c == "\n"
          lines << chars
          chars = []
        #if we are within 10 characters of the line character limit, start looking for logical word separators
        elsif chars.length > @line_char_limit-10
          chars << [ c, i ]

          #if we find a comma, period or space, move on to the next line
          if c.match(/(\.|\s|,)/)
            lines << chars
            chars = []
          end
        #otherwise just append the character to our character array
        else
          chars << [ c, i ]
        end
      end

      if isMarkup && c == '>'
        isMarkup = false
      end

      @char_index << nil
    end
    lines.each_with_index do |line, i|
      if line.size == 0
        @line_index << nil
      else
        found = false
        break_points = []#tracks any breakpoints where text is hidden mid-line
        line.each_with_index do |c, j|
          #add a breakpoint pair if the sequence breaks down
          if j > 0 && c[1]-1 != line[j-1][1]
            break_points.concat [ line[j-1][1], c[1] ]
          end
          @char_index[c[1]] = [ i, j ] # maps global char index to line index and within-line index
        end
        # maps line index to first and last char indices
        if break_points.length > 0
          #if we found breakpoints, put them in the middle of the array in the expected order
          @line_index << [ line[0][1] ].concat(break_points).concat([ line[-1][1] ])
        else
          @line_index << [ line[0][1], line[-1][1] ]
        end
      end
    end
  end

  #this function transforms an OSC document, extracting the necessary metadata, and hiding the necessary parts
  def transform_OSC(original_text)
    calculate_line_char_limit original_text
    original_text << "\n" unless original_text[-1] == "\n"
    chars = []
    lines = [Array.new]
    isText = false
    isTextCounter = 0
    horizontal_line_breaks = []
    isSquareBracket = false
    original_text.split('').each_with_index do |c, i|
      if original_text[i..i+10].start_with?('TEXT:') && !original_text[i..i+30].include?('UNCLAS')
        isText = true
        isTextCounter == 7 ? isTextCounter = 0 : isTextCounter += 1
      end
      if isText && isTextCounter < 7
        isTextCounter += 1
      end
      if isText && isTextCounter == 7
        if original_text[i..i+10].start_with?('(MORE)') || original_text[i..i+10].start_with?('(ENDALL)')
          horizontal_line_breaks << lines.length
          isTextCounter = 0
          isText = false
        end

        if c == '['
          isSquareBracket = true
          lines << chars
          chars = []
        end

        if !isSquareBracket && isText
          #if there is an existing line break before the character limit for a line, start a new line
          if c == "\n"
            lines << chars
            chars = []
          #if we are within 10 characters of the line character limit, start looking for logical word separators
          elsif chars.length > @line_char_limit-10
            chars << [ c, i ]

            #if we find a comma, period or space, move on to the next line
            if c.match(/(\.|\s|,)/)
              lines << chars
              chars = []
            end
          #otherwise just append the character to our character array
          else
            chars << [ c, i ]
          end
        end
      end

      if c == ']'
        isSquareBracket = false
      end

      @char_index << nil
    end

    #extract metadata
    @meta[:headers] = {}
    original_text.match(/INFODATE:\s+(\d+)/)
    @meta[:headers]['INFODATE'] = $1
    original_text.match(/DOCCOUNTRY:\s+(\w+)/)
    @meta[:headers]['DOCCOUNTRY'] = $1

    #add horizontal line break list into meta data for processing
    @meta[:horizontal_line_breaks] = horizontal_line_breaks

    lines.each_with_index do |line, i|
      if line.size == 0
        @line_index << nil
      else
        line.each_with_index do |c, j|
          @char_index[c[1]] = [ i, j ] # maps global char index to line index and within-line index
        end
        @line_index << [ line[0][1], line[-1][1] ] # maps line index to first and last char indices
      end
    end
  end

  #this function performs the default transform behavior
  # see comments below for data structure
  # this first line is @line_index[1], rather than [0]
  def transform_default(original_text)
    original_text << "\n" unless original_text[-1] == "\n"
    chars = []
    lines = [Array.new]

    # display length of the current line
    # each uppcase letter counts as 1.5 chars
    # each CJK character counts as 2 chars
    # everything else counts as 1 char
    current_line_display_length = 0

    original_text.split('').each_with_index do |c, i|
      #if there is an existing line break before the character limit for a line, start a new line
      if c == "\n"
        lines << chars
        chars = []
        current_line_display_length = 0
      #if we are within 10 characters of the line character limit, start looking for logical word separators
      elsif current_line_display_length > @line_char_limit-10 and current_line_display_length < @line_char_limit
        chars << [ c, i ]
        if c.match(/[A-Z]/)
          current_line_display_length += 1.5
        elsif c.match(/\p{Han}/)
          current_line_display_length += 2
        else
          current_line_display_length += 1
        end

        #if we find a space or punctuation, move on to the next line
        if c.match(/(\s|\p{Punctuation})/)
          lines << chars
          chars = []
          current_line_display_length = 0
        end
      # force line break if the current line is longer than the line_char_limit
      elsif current_line_display_length > @line_char_limit
        chars << [ c, i ]
        lines << chars
        chars = []
        current_line_display_length = 0
      # otherwise just append the character to our character array
      else
        chars << [ c, i ]
        if c.match(/[A-Z]/)
          current_line_display_length += 1.5
        elsif c.match(/\p{Han}/)
          current_line_display_length += 2
        else
          current_line_display_length += 1
        end
      end

      @char_index << nil
    end
    lines.each_with_index do |line, i|
      if line.size == 0
        @line_index << nil
      else
        line.each_with_index do |c, j|
          @char_index[c[1]] = [ i, j ] # maps global char index to line index and within-line index
        end
        @line_index << [ line[0][1], line[-1][1] ] # maps line index to first and last char indices
      end
    end
  end

  #this function performs the default transform behavior
  def transform_chinese(original_text)
    original_text << "\n" unless original_text[-1] == "\n"
    chars = []
    lines = [Array.new]
    original_text.split('').each_with_index do |c, i|
      #if there is an existing line break before the character limit for a line, start a new line
      if c == "\n"
        lines << chars
        chars = []
      elsif chars.length == 30
        chars << [ c, i ]
        lines << chars
        chars = []
      #otherwise just append the character to our character array
      else
        chars << [ c, i ]
      end

      @char_index << nil
    end
    lines.each_with_index do |line, i|
      if line.size == 0
        @line_index << nil
      else
        line.each_with_index do |c, j|
          @char_index[c[1]] = [ i, j ] # maps global char index to line index and within-line index
        end
        @line_index << [ line[0][1], line[-1][1] ] # maps line index to first and last char indices
      end
    end
  end


  module SentenceSegmenters
    # Taken from /ldc/bin/chinese_sentence_segmentor_utb8.rb
    def self.cmn(str)
      lines = []
      str.each_line do |line|
        line.gsub!(/([。！？!\?]+["\]]?)/, "\\1\n")
        lines << line
      end
      lines.join
    end
  end

  # break text into sentences
  #
  # (currently a stub)
  def transform_sentences(original_text, segmenter=nil)
    text = original_text.dup
    text.chomp!

    # Normalize whitespace
    text.gsub! /\s/, ' '

    # Force sentence breaks between end tags and start tags
    text.gsub! /(<\/[^>]*>\s*)\s(<[^\/>]*>)/, "\\1\n\\2"

    # Replace all XML/HTML tags with whitespace (preserving length)
    text.gsub!(/<[^>]*>/) { |s| ' ' * s.length }

    # If segmenter is passed, fetch associated segmenter from SentenceSegmenters
    if segmenter and not segmenter.empty?
      seg = SentenceSegmenters.method segmenter
      output = seg.call text
    else # Use segmenter set in LDCI::CONFIG
      # Pipe to external sentence segmenter
      output = IO.popen(LDCI::CONFIG[:sentence_segmenter], 'r+') do |pipe|
        pipe.write text
        pipe.close_write
        pipe.read
      end
    end

    @char_index = []
    @line_index = []
    m = 0 # m, n are first and last chars in range mapped by sentence
    nils = 0
    output.lines.each_with_index do |sentence, i|
      n = m + sentence.length - 1

      if segmenter == 'cmn'
        n -= 1 if text[n] !~ /\n/ # sentence segmenter adds newlines
      else
        n -= 1 if text[n] !~ /\s/ # sentence segmenter adds newlines
      end
      unless sentence =~ /\S/
        nils += 1
        (m..n).each { @char_index << nil }
        m = n + 1
        next
      end
      first = m + (sentence =~ /\S/) # first non-whitespace character
      last = m + (sentence =~ /\s*$/) - 1 # last non-whitespace character
      (m...first).each { @char_index << nil }
      (first..last).each_with_index { |_,j| @char_index << [i - nils, j] }
      (last...n).each { @char_index << nil }
      @line_index << [ first, last ]
      m = n + 1
    end
  end
end
end
