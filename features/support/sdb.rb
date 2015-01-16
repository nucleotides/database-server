module SDB
  require 'fog/aws/simpledb'

  def self.client
    Fog::AWS::SimpleDB.new(
      aws_access_key_id:     ENV['AWS_ACCESS_KEY'],
      aws_secret_access_key: ENV['AWS_SECRET_KEY'],
      region:                ENV['AWS_REGION'])
  end

  def self.create
    client.create_domain(ENV['AWS_SDB_DOMAIN'])
  end

  def self.destroy
    client.delete_domain(ENV['AWS_SDB_DOMAIN'])
  end

end
