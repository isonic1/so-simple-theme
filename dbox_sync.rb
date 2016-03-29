#!/usr/bin/env ruby
require "dbox"
require 'dropbox_sdk'

client = DropboxClient.new(ENV["DROPBOX_ACCESS_TOKEN"])

FOLDERS = client.metadata('/')["contents"].map { |folder| folder["path"].tr("/","") if folder["icon"] == "folder" }.compact
LOCAL_PATH = "/home/ec2-user/photos"
LOGFILE = "/home/ec2-user/dbox.log"
INTERVAL = 60 # time between syncs, in seconds

LOGGER = Logger.new(LOGFILE, 1, 1024000)
LOGGER.level = Logger::INFO

def main
  while 1
    begin
      sync
    rescue Interrupt => e
      exit 0
    rescue Exception => e
      LOGGER.error e
    end
    sleep INTERVAL
  end
end

def sync
  FOLDERS.each do |folder|
    unless Dbox.exists?("#{LOCAL_PATH}/#{folder}")
      LOGGER.info "Cloning"
      Dbox.clone(folder, "#{LOCAL_PATH}/#{folder}")
      LOGGER.info "Done"
    else
      LOGGER.info "Syncing"
      Dbox.push("#{LOCAL_PATH}/#{folder}")
      Dbox.pull("#{LOCAL_PATH}/#{folder}")
      LOGGER.info "Done"
    end
  end
end

main