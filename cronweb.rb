# cronweb.rb is a simple Sinatra application that provides an overview
# over cronwrap'd jobs' status and a view onto the individual jobs logs
# jon@zomo.co.uk. See README for blurbs.

require 'rubygems'
require 'sinatra'
require 'haml'

LOG_DIR=ENV['CRONWRAP_LOG_DIR']   || '/data/cron' # where cronwrap logs are
WEB_PATH=ENV['CRONWRAP_WEB_PATH'] || '/cron'      # write URLs relative to this (does Sinatra have route-aware url helpers?)

def job_status(log_dir, job)
  dir = "#{log_dir}/#{job}"
  if File.exist?("#{dir}/status/OK")
    STDERR.puts "#{dir} OK"
    status = 'OK'
    stamp   = File.read("#{dir}/status/OK")
  elsif File.exist?("#{dir}/status/LOCK")
    STDERR.puts "#{dir} LOCK"
    status = 'LOCK'
    stamp   = File.read("#{dir}/status/LOCK")
  else
    STDERR.puts "#{dir} FAIL"
    status = 'FAIL'
    stamp   = File.read("#{dir}/status/FAIL")
  end
  return { :status => status, :stamp => stamp }
end

# list of cronwrap'd jobs and their health
get "#{WEB_PATH}/" do
  @jobs   = Dir.entries(LOG_DIR) - [ '.', '..']
  @status = {}
  @jobs.each { |j| @status[j] = job_status(LOG_DIR, j)[:status] }
   
  haml :index
end

# individual cronwrap'd job status
get "#{WEB_PATH}/:job/status" do
  @job = params[:job]
  @dir = "#{LOG_DIR}/#{@job}"
  status   = job_status(LOG_DIR, @job)
  @overall = status[:status]
  @stamp   = status[:stamp]
  @totals = {
    :job_ok    => File.readlines("#{@dir}/status/job_ok").length,
    :job_fail  => File.readlines("#{@dir}/status/job_fail").length,
    :lock_fail => File.readlines("#{@dir}/status/lock_fail").length,
  }
  haml :status
end

# permalink to last job_ok, last lock_fail etc
get "#{WEB_PATH}/:job/last/:condition" do
  @job = params[:job]
  @condition = params[:condition]
  @dir = "#{LOG_DIR}/#{@job}"
  begin
    link = File.readlink("#{@dir}/last_#{@condition}")
    @log = File.read("#{@dir}/#{File.basename(link)}")
  rescue Errno::ENOENT
    @log = "(no log found)"
  end
  haml :log
end

# concatenate all logs for this job
# nothing clever here, if there's lots of jobs then something somwhere will be sad
get "#{WEB_PATH}/:job/all" do
  @job = params[:job]
  @dir = "#{LOG_DIR}/#{@job}"
  @log = []
  Dir.glob("#{@dir}/*.log").each do |f|
    @log.push(File.read(f))
  end
  haml :log
end

__END__

@@ layout
!!!
%html
  = yield

@@ index
%h1 cron jobs
#joblist
  %ul
    - @jobs.each do |j|
      %li
        %a{:href => "#{WEB_PATH}/#{j}/status"} #{j} (#{@status[j]})

@@ status
%h1= @job
#summary
  %table
    %tr
      %td status
      %td #{@overall}
    %tr
      %td date
      %td #{@stamp}
    %tr
      %td job_ok
      %td #{@totals[:job_ok]}
    %tr
      %td job_fail
      %td #{@totals[:job_fail]}
    %tr
      %td lock_fail
      %td #{@totals[:lock_fail]}
#links
  %ul
    %li
      %a{:href => "#{WEB_PATH}/#{@job}/last/job_ok"} Log for last successful run
    %li
      %a{:href => "#{WEB_PATH}/#{@job}/last/job_fail"} Log for last failed run
    %li
      %a{:href => "#{WEB_PATH}/#{@job}/last/lock_fail"} Log for last lock failure
    %li
      %a{:href => "#{WEB_PATH}/#{@job}/all"} All logs on record

@@ log
%h1= @job
%pre= @log
