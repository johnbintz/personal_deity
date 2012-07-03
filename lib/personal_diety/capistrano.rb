require 'capistrano'
require 'personal_diety'
require 'erb'

Capistrano::Configuration.instance(true).load do
  def _cset(name, *args, &block)
    set(name, *args, &block) if !exists?(name)
  end

  _cset(:god_port) { 23132 }
  _cset(:god_log_level) { :warn }
  _cset(:personal_diety_local_app_config) { 'config/god.conf' }

  def personal_diety_target
    @personal_diety_target ||= Pathname(capture("echo $HOME/personal_diety").strip)
  end

  def personal_diety_config_dir
    Pathname("#{personal_diety_target}/god.d")
  end

  def personal_diety_command
    personal_diety_target.join("god")
  end

  def generate_personal_diety_command(*args)
    "cd #{personal_diety_target} && #{personal_diety_command} #{args.join(' ')}"
  end

  def run_personal_diety_command(*args)
    run generate_personal_diety_command(*args) + "; true"
  end

  namespace :personal_diety do
    desc "Install the God config for this app"
    task :install do
      template = ERB.new(File.read(personal_diety_local_app_config)).result(binding)
      upload_target = personal_diety_config_dir.join("#{application}.god")
      top.upload StringIO.new(template), upload_target.to_s

      run_personal_diety_command :load, upload_target.to_s
    end

    namespace :service do
      desc "Set up a copy of God to run for this user"
      task :setup do
        run "mkdir -p #{personal_diety_config_dir.to_s}"

        config_path = "#{personal_diety_target}/god.conf"

        PersonalDiety.skel.capistrano.find do |file|
          if file.file?
            template = ERB.new(file.read).result(binding)
            upload_target = personal_diety_target.join(file.relative_path_from(PersonalDiety.skel.capistrano))
            top.upload StringIO.new(template), upload_target.to_s
            run "chmod #{file.stat.mode.to_s(8)[-3..-1]} #{upload_target}"
          end
        end

        run "cd #{personal_diety_target} && bundle install --path gems"
        run "cd #{personal_diety_target} && bundle exec whenever -i god -f schedule.rb"
      end

      desc "Stop the God service"
      task :stop do
        run_personal_diety_command :quit
      end

      desc "Start the God service"
      task :start do
        run_personal_diety_command
      end

      desc "Restart the God service"
      task :restart do
        top.personal_diety.service.stop
        top.personal_diety.service.start
      end
    end

    desc "Stop the God process for this application"
    task :stop do
      run_personal_diety_command :stop, application
    end

    desc "Start the God process for this application"
    task :start do
      run_personal_diety_command :start, application
    end

    desc "Restart the God process for this application"
    task :restart do
      run_personal_diety_command :restart, application
    end
  end

  before 'deploy:update_symlink', 'personal_diety:install'
  before 'deploy:symlink', 'personal_diety:install'

  namespace :deploy do
    task(:stop) { top.personal_diety.stop }
    task(:start) { top.personal_diety.start }
    task(:restart) { top.personal_diety.restart }
  end
end

