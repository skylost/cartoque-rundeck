# Chargement des dependances
require 'sinatra/base'
require 'builder/xchar'
require "open-uri"
require "json"
require "yaml"

 # Classe Cartoquerundeck
class CartoqueRundeck < Sinatra::Base

  config = YAML.load_file(settings.root + '/../config/cartoque-rundeck.yml')
  @@cartoque_url = config['cartoque']['url']
  @@cartoque_token = config['cartoque']['token']

  class << self
    def configure
    end
  end

  def xml_escape(input)
    return input.to_s.to_xs
  end

  def respond(db_type=nil)
    response['Content-Type'] = 'text/xml'
    response_xml = %Q(<?xml version="1.0" encoding="UTF-8"?>\n<!DOCTYPE project PUBLIC "-//DTO Labs Inc.//DTD Resources Document 1.0//EN" "project.dtd">\n<project>\n)
    
    #on recupere le json venant de cartoque
    databases_json = open("#{@@cartoque_url}/databases?include=servers.json", "X-Api-Token" => @@cartoque_token, :proxy => false).read
    databases = JSON.parse(databases_json)

    databases.each do |hash|
      hash[1].each do |id|
        if id['type'] == db_type then
          if id['servers'] then
            id['servers'].each do |server|
              if server['operating_system'] then
                response_xml << <<-EOH
<node name="#{id['name']}"
      type="Node"
      description="#{id['name']}"
      osArch="Linux"
      osFamily="unix"
      osName="#{server['operating_system']['name'].split(" ")[0]}" 
      osVersion="#{server['operating_system']['name'].split(" ")[1]}" 
      tags="production,#{db_type}"
      username="rundeck"
      hostname="#{id['name']}"/>
EOH
              else 
                response_xml << <<-EOH
<node name="#{id['name']}"
      type="Node"
      description="#{id['name']}"
      osArch="Linux"
      osFamily="unix"
      osName="Debian" 
      osVersion="7.0" 
      tags="production,#{db_type}"
      username="rundeck"
      hostname="#{id['name']}"/>
EOH
              end
            end
          else 
            response_xml << <<-EOH
<node name="#{id['name']}"
      type="Node"
      description="#{id['name']}"
      osArch="Linux"
      osFamily="unix"
      osName="Debian"
      osVersion="7.0"
      tags="production,#{db_type}"
      username="rundeck"
      hostname="#{id['name']}"/>
EOH
          end
        end
      end
    end
    response_xml << "</project>"
    response_xml
  end

  get '/databases' do
    respond
  end

  get '/databases/type/:type' do
    respond(params[:type])
  end

end
