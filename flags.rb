cookbook_file '/tmp/super_secret_db.sql' do
  source 'flags/super_secret_db.sql'
  mode '0755'
end
