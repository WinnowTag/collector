fork do
  [STDOUT,STDERR].each {|f| f.reopen '/dev/null', 'w' }
  exec('mongrel_rails start -e test -p 4000')
end
