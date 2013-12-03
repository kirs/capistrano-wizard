require 'spec_helper'

require 'fileutils'

describe CapistranoWizard do
  after do
    FileUtils.rm_rf("result")
  end
  it "works" do
    # do in silent
    described_class.start([
      "dumb", "rbenv", "git@github.com:org/name", "/home/vagrant/appname", "beta,production"
    ])

    capfile = File.open(File.join("result", "Capfile")).read
    deploy_rb = File.open(File.join("result", "config/deploy.rb")).read

    expect(capfile).to include "require 'capistrano/rbenv'"
    expect(deploy_rb).to include "set :deploy_to, '/home/vagrant/appname'"
    expect(deploy_rb).to include "set :repo_url, 'git@github.com:org/name'"

    beta_file = File.join("result", "config", "deploy", "beta.rb")
    expect(File.exists?(beta_file)).to be_true

    production_file = File.join("result", "config", "deploy", "production.rb")
    expect(File.exists?(production_file)).to be_true
  end
end
