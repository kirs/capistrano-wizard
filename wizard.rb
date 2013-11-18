require 'thor'

class CapistranoWizard < Thor::Group
  include Thor::Actions

  def self.source_root
    File.dirname(__FILE__)
  end

  def create_capfile
    @plugins = []

    if yes?("Use Rails integration?")
      @plugins << :rails
    else
      if yes?("Use Bundler integration?")
      @plugins << :bundler
      end
    end

    if yes?("Do you want to use Ruby version manager?")
      ask_ruby_version_manager
    end

    template("templates/Capfile.erb", "result/Capfile")
  end

  def create_deploy_file
    @application_name = ask("Application name?")
    @repo_url = ask("Repo url (example git@example.com:me/my_repo.git):")

    set_deploy_to

    template("templates/deploy.rb.erb", "result/config/deploy.rb")
  end

  def create_stages
    default_stages = %w(production staging)

    @stages = ask("Which stages do you want to use (defaults are #{default_stages.join(', ')}})?")
    if @stages.strip.empty?
      @stages = default_stages
    else
      @stages = @stages.split(/[\s,]+/)
    end

    @stages.each do |stage_name|
      raw_credentials = ask("Enter credentials for #{stage_name} in user@host.com format:")
      if credentials = raw_credentials.split("@")
        @username = credentials[0]
        @host = credentials[1]
      end

      @stage_name = stage_name
      template("templates/stage.rb.erb", "result/config/deploy/#{stage_name}.rb")
    end
  end

  private

  def set_deploy_to
    deploy_to_default = "/var/www/#{@application_name}"
    @deploy_to = ask("Deploy to path (default: #{deploy_to_default}): ")

    if @deploy_to.empty?
      @deploy_to = deploy_to_default
    end
  end

  def ask_ruby_version_manager
    say "Available Ruby version managers:"
    available = %w(rbenv rvm chruby)
    available.each do |manager|
      say manager
    end

    while !available.include?(@ruby_manager)
      @ruby_manager = ask("Which one do you want to use?")
    end

    case @ruby_manager
    when "rbenv"
      say "asking for :rbenv_ruby"
    when "rvm"
      say "asking for :rvm_ruby"
    when "chruby"
      say "asking for :chruby_ruby"
    end

    @plugins << @ruby_manager
  end
end

CapistranoWizard.start
