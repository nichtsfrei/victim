cookbook_file '/tmp/drupal.sql' do
  source 'drupal/drupal.sql'
  mode '0755'
end
