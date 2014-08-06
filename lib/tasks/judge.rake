namespace :judge do
  desc "TODO"
  task :compile, [:filename] => [:environment] do |t,args|
    puts args[:filename]
  end
end
