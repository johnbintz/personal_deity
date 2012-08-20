require 'capistrano'
require 'personal_deity'
require 'erb'

Capistrano::Configuration.instance(true).load do
  def _cset(name, *args, &block)
    set(name, *args, &block) if !exists?(name)
  end

  _cset(:god_port) { 23132 }
  _cset(:god_log_level) { :warn }
  _cset(:personal_deity_local_app_config) { 'config/god.conf' }

  def personal_deity_target
    @personal_deity_target ||= Pathname(capture("echo $HOME/personal_deity").strip)
  end

  def personal_deity_config_dir
    Pathname("#{personal_deity_target}/god.d")
  end

  def personal_deity_command
    personal_deity_target.join("god")
  end

  def generate_personal_deity_command(*args)
    "cd #{personal_deity_target} && #{personal_deity_command} #{args.join(' ')}"
  end

  def run_personal_deity_command(*args)
    run generate_personal_deity_command(*args) + "; true"
  end

  actions = [ :stop, :start, :restart ]

  namespace :personal_deity do
    desc "Install the God config for this app"
    task :install do
      upload_target = personal_deity_config_dir.join("#{application}.god")

      run_personal_deity_command :stop, upload_target.to_s

      template = ERB.new(File.read(personal_deity_local_app_config)).result(binding)
      top.upload StringIO.new(template), upload_target.to_s

      run_personal_deity_command :load, upload_target.to_s
      run_personal_deity_command :start, upload_target.to_s
    end

    namespace :service do
      desc "Set up a copy of God to run for this user"
      task :setup do
        run "mkdir -p #{personal_deity_config_dir.to_s}"

        config_path = "#{personal_deity_target}/god.conf"

        PersonalDeity.skel.capistrano.find do |file|
          if file.file?
            template = ERB.new(file.read).result(binding)
            upload_target = personal_deity_target.join(file.relative_path_from(PersonalDeity.skel.capistrano))
            top.upload StringIO.new(template), upload_target.to_s
            run "chmod #{file.stat.mode.to_s(8)[-3..-1]} #{upload_target}"
          end
        end

        run "cd #{personal_deity_target} && bundle install --path gems"
        run "cd #{personal_deity_target} && bundle exec whenever -i god -f schedule.rb"
      end

      desc "Stop the God service"
      task :stop do
        run_personal_deity_command :quit
      end

      desc "Start the God service"
      task :start do
        run_personal_deity_command
      end

      desc "Restart the God service"
      task :restart do
        top.personal_deity.service.stop
        top.personal_deity.service.start
      end
    end

    actions.each do |method|
      desc "#{method.to_s.capitalize} the God process for this application"
      task(method) do
        run_personal_deity_command method, application
      end
    end
  end

  namespace :deploy do
    actions.each do |method|
      task(action) { top.personal_deity.send(method) }
    end
  end
end

