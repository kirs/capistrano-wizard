require 'thor'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/object/blank'

class CapistranoWizard < Thor::Group
  include Thor::Actions

  # argument :rails, type: :boolean
  # argument :bundler, type: :boolean

  # class_option :rails, type: :boolean, desc: "Use rails or not"

  argument :application_name, type: :string, required: false
  argument :ruby_version_manager, type: :string, required: false
  argument :repo_url, type: :string, required: false
  argument :deploy_to, type: :string, required: false
  argument :stages, type: :string, required: false

  def self.source_root
    File.dirname(__FILE__)
  end

  def create_capfile
    @plugins = []

    # if rails.blank? && bundler.blank?
    #   if yes?("Use Rails integration?")
    #     self.rails = true
    #   else
    #     if yes?("Use Bundler integration?")
    #       self.bundler = true
    #     end
    #   end
    # end

    if ruby_version_manager.blank?
      if yes?("Do you want to use Ruby version manager?")
        ask_ruby_version_manager
      end
    end

    if ruby_version_manager.present?
      @plugins << ruby_version_manager
    end

    template("templates/Capfile.erb", "result/Capfile")
  end

  def create_deploy_file
    if application_name.blank?
      self.application_name = ask("Application name?")
    end

    clean_application_name = application_name.underscore

    if clean_application_name != application_name
      puts "Application name cleaned to '#{clean_application_name}'"
      self.application_name = clean_application_name
    end

    if deploy_to.blank?
      set_deploy_to
    end

    if repo_url.blank?
      set_repo_url
    end

    template("templates/deploy.rb.erb", "result/config/deploy.rb")
  end

  def create_stages
    if stages.blank?
      default_stages = %w(production staging)

      self.stages = ask("Which stages do you want to use (defaults are #{default_stages.join(', ')}})?")
    end

    self.stages = if stages.strip.empty?
      default_stages
    else
      stages.split(/[\s,]+/)
    end

    stages.each do |stage_name|
      # raw_credentials = ask("Enter credentials for #{stage_name} in user@host.com format:")
      # if credentials = raw_credentials.split("@")
      #   @username = credentials[0]
      #   @host = credentials[1]
      # end

      @stage_name = stage_name
      template("templates/stage.rb.erb", "result/config/deploy/#{stage_name}.rb")
    end
  end

  private

  def set_deploy_to
    deploy_to_default = "/var/www/#{@application_name}"
    self.deploy_to = ask("Deploy to path (default: #{deploy_to_default}): ")

    if deploy_to.empty?
      self.deploy_to = deploy_to_default
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
  end

  def set_repo_url
    self.repo_url = ask("Repo url (example git@example.com:me/my_repo.git):")
  end
end
