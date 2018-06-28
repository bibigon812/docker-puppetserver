#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'

config = {
  'cachedir' => ENV['CACHE_DIR'],
  'sources'  => {
    'basedir' => ENV['ENVIRONMENTS_BASE_DIR'],
    'remote'  => ENV['GIT_REMOTE']
  }
}

File.write("#{ENV['R10K_CONFIG_DIR']}/r10k.yaml", config.to_yaml)
