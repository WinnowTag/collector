# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
task :cruise do
  ENV['RAILS_ENV'] = RAILS_ENV = 'test'
  Rake::Task['gems:build'].invoke
  Rake::Task['db:migrate'].invoke
  # Rake::Task['assets:clean'].invoke
  # system "touch tmp/restart.txt"
  
  Rake::Task['spec:code'].invoke
  Rake::Task['spec:controllers'].invoke
  Rake::Task['spec:lib'].invoke
  Rake::Task['spec:models'].invoke
  Rake::Task['spec:views'].invoke
  Rake::Task['features'].invoke
  # Rake::Task['selenium:rc:start'].invoke
  # Rake::Task['selenium'].invoke
  # Rake::Task['selenium:rc:stop'].invoke

  # TODO: This needs to span specs, features, and selenium
  # Rake::Task['rcov_for_cc'].invoke
end
