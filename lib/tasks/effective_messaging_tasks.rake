namespace :effective_messaging do

  # bundle exec rake effective_messaging:seed
  task seed: :environment do
    load "#{__dir__}/../../db/seeds.rb"
  end

end
