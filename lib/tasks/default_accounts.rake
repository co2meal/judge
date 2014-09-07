# coding: utf-8

namespace :judge do
  task :default_accounts => :environment do
    AdminUser.create!([
      {email: "admin@example.com", password: "password", password_confirmation: "password"}
    ])
    User.create!([
      {email: "co2meal@gmail.com", password: "12341234", password_confirmation: "12341234"}
    ])
  end
end
