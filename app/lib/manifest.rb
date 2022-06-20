#!/usr/bin/env ruby
# Usage: x = Manifest.new(table_name, task, data_set)
# x.make_json_manifest # creates "taskid_datasetid.json"
# Spec:
# { "list": [], "data": {}, "files": [] }

require 'json'

class Manifest
    def initialize(table_name, target_location)
        @table_name = table_name
        @target_location = target_location
    end

    def make_json_manifest
        table_array = file_to_array(@table_name)
        table_json = array_to_json(table_array)
        write_manifest(table_json)
    end

    def file_to_array(table_name)
        table_array = []
        header = []
        num_cols = nil
        File.readlines(table_name).map do |line|
            current = line.gsub(/\r?\n/,"").split(/\t/)
            current.each { |x| x.strip! } # because webann is dumb and adds spaces to text
            if current.size < 2
                STDERR.puts "skipping blank manifest line"
                next
            end
            if header.size.zero?
                header = current
                num_cols = current.size
                next
            end
            if current.size != num_cols
                STDERR.puts "inconsistent number of columns in row in manifest"
                next
            end
            table_array << Hash[header.zip(current)]
        end
        table_array
    end

    def array_to_json(table_array)
        table_json = {list: table_array}.to_json
    end

    def write_manifest(table_json)
        File.open(@target_location, "w") {|f| f.puts table_json }
    end
end