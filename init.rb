#!/usr/bin/env ruby
# frozen_string_literal: true

cache_dir                    = ENV['CACHE_DIR']
git_remote                   = ENV['GIT_REMOTE']
puppet_environemnts_base_dir = ENV['ENVIRONMENTS_BASE_DIR']

require 'erb'

File.write(
  ENV['R10K_CONFIG_FILE'],
  ERB.new(File.read(ENV['R10K_CONFIG_TEMPLATE'])).result(binding)
)

