module HTTP
  require 'curl'

  def self.post(endpoint, params)
    Curl.post(docker_url + endpoint, params)
  end

  def self.get(endpoint, query = {})
    base = docker_url + endpoint
    if not query.empty?
      url = query.inject(base + "?") do |string, (k,v)|
        string + k.to_str + '=' + v.to_str
      end
    end
    Curl.get(url)
  end

end
