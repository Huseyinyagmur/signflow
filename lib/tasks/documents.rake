namespace :documents do
  desc "Persist expired status for documents whose signing deadline has passed"
  task expire: :environment do
    Documents::Expiration.call
    puts "Expired document sweep completed."
  end
end
