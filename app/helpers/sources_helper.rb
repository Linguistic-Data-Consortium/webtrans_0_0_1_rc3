# encoding: utf-8
module SourcesHelper

  # require 'zip'
  require 'cgi'
  require 'net/http'
  require 'uri'

  def get_source_audio(docid)
    docid, b, e = docid.split ','
    return LDCI.uget( { :id =>  docid, :type => 'audio', :beg => b, :end => e }.to_json )
    return File.read "/Users/jdwright/Downloads/test.wav"
    
    send_data `./trim #{params[:path]} #{params[:beg]} #{params[:end]}`

    obj = Source.find_by_docid docid
    http = Net::HTTP.new(obj.host + '.ldc.upenn.edu', 443)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    if Rails.env.development?
      headers = { 'Cookie' => URI.escape(File.read(File.expand_path("~/.lui.webann")).chomp, "+") }
    else
      headers =  { 'Cookie' => URI.escape("remember_token=#{cookies[:remember_token]}", "+") }
    end
    resp, file = http.post('/sources', "path=#{obj.path}&beg=#{b}&end=#{e}", headers)
    resp.body
  end

  # can't eliminate this yet, a lot of files call it
  # eliminated from sources constroller
  def get_source_text(docid, transform_flag=false, type='document', source_media='normal')    
    raise "don't use"
    file = LDCI.uget( { :id =>  docid, :type => type }.to_json )
    if type == 'document'
      file.force_encoding 'UTF-8'
      LDCI::Document.new(docid, file, transform_flag, source_media).get_hash
    else
      JSON.parse(file)
    end 
  end
  
=begin This is code which can be used to grab a post context +/- 5 posts around a specified post id
    numerical_id = post_id[1..-1].to_i
    posts_ids = (numerical_id-5..numerical_id+5).to_a.collect {|x| "p#{x}" }
    posts = String.new
    posts_ids.each do |pid|
      file =~ /(<post .*id="(#{pid})"(.|\n)+?<\/post>)/
      posts += $1 unless $1.nil?
    end
    #file =~ /((<post (.|\n)*?<\/post>){5}<post .*id="#{post_id}"(.|\n)+?<\/post>(<post (.|\n)*?<\/post>){5})/
=end

end
