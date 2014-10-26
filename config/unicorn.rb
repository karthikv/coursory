require 'dotenv'
Dotenv.load

working_directory ENV['UNICORN_WORKING_DIR']
worker_processes Integer(ENV['UNICORN_WORKERS'] || 4)

timeout 30
preload_app true

listen(ENV['UNICORN_SOCKET'], :backlog => Integer(ENV['UNICORN_BACKLOG'] || 200))
stderr_path ENV['UNICORN_STDERR_PATH']
stdout_path ENV['UNICORN_STDOUT_PATH']

before_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
    Process.kill 'QUIT', Process.pid
  end
end

after_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn worker intercepting TERM and doing nothing. Wait for' +
      ' master to send QUIT'
  end
end
