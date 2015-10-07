require 'fog'
require 'hashie/mash'

module SDB
  class << self

    ENV_KEYS = ['ACCESS_KEY', 'SECRET_KEY', 'ENDPOINT', 'SDB_DOMAIN']

    def region(endpoint)
      matches = endpoint.match(/https:\/\/sdb.([^.]*)\.amazonaws\.com/).captures
      matches.first
    end

    def test_credentials
      ENV_KEYS.map{|i| "AWS_" + i}.each do |key|
        if (ENV[key].nil? or ENV[key].empty?)
          raise ArgumentError, "Environment variable not set: #{key}"
        end
      end
    end

    def fetch_credentials
      creds = Hash[ENV_KEYS.map do |key|
        [key.downcase.to_sym, ENV["AWS_" + key]]
      end]
      creds[:region] = region(creds[:endpoint])
      Hashie::Mash.new(creds)
    end

    def credentials
      if @credentials_.nil?
        test_credentials
        @credentials = fetch_credentials
      end
      @credentials
    end

    def client
      Fog::AWS::SimpleDB.new(
        aws_access_key_id:     credentials.access_key,
        aws_secret_access_key: credentials.secret_key,
        region:                credentials.region)
    end

    def create
      client.create_domain(credentials.sdb_domain)
    end

    def destroy
      client.delete_domain(credentials.sdb_domain)
    end

    def refresh
      destroy
      create
    end

    def add_records(records)
      client.batch_put_attributes(credentials.sdb_domain, records)
    end

  end
end
