namespace :database do

  desc "setup new database"
  task :change, [:name] do |t, args|
    #puts args[:name]
    fn = '.envv/development/database'
    x = File.read fn
    pw = x.split.select { |x| x =~ /PASSWORD/ }.first.sub 'POSTGRES_PASSWORD', 'PGPASSWORD'
    x.sub! /POSTGRES_DB=.+/, "POSTGRES_DB=#{args[:name]}"
    File.write fn, x
    c = "docker-compose exec -e #{pw} database psql -U postgres -h database -c 'create database #{args[:name]};'"
    puts c
    #puts x
  end

  desc "load paths into sources table"
  task :load_source_paths, [:b, :e, :dn] => [:environment] do |t, args|
    Source.where(id: [args[:b]..args[:e]]).each do |x|
      fn = "#{args[:dn]}/#{x.uid}"
      puts fn
      if File.exists? fn
        puts 'found'
        x.file.attach( io: File.open(fn), filename: File.basename(fn) )
      end
    end
  end

end
