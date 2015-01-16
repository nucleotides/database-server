module SDB
  require 'fog/aws/simpledb'

  def self.client
    Fog::AWS::SimpleDB.new(
      aws_access_key_id:     ENV['AWS_ACCESS_KEY'],
      aws_secret_access_key: ENV['AWS_SECRET_KEY'],
      region:                ENV['AWS_REGION'])
  end

  def self.domain
    ENV['AWS_SDB_DOMAIN']
  end

  def self.create
    client.create_domain(domain)
  end

  def self.destroy
    client.delete_domain(domain)
  end

  def self.refresh
    destroy
    create
  end

  def self.add_records(records)
    client.batch_put_attributes(domain, records)
  end

end
