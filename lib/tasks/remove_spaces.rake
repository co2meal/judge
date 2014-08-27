# coding: utf-8

namespace :judge do
  task :remove_spaces => :environment do
    Submission.where("status LIKE ?", "%\n%").each do |submission|
      submission.update(:status => submission.status.strip)
    end
  end
end
