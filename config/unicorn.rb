project_path = "/home/deployer/projects/tipcalc"
shared_path = "#{ project_path }/shared"
user "deployer"
worker_processes 4
working_directory "#{ project_path }/current"
listen "#{ shared_path }/unicorn/tipcalc.sock"
pid "#{ shared_path }/unicorn/unicorn.pid"
stderr_path "#{ shared_path }/unicorn/log/unicorn_err.log"
stdout_path "#{ shared_path }/unicorn/log/unicorn_out.log"