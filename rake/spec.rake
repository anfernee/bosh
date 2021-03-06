require "rspec"
require "rspec/core/rake_task"

namespace :spec do
  desc "Run BOSH integration tests against a local sandbox"
  RSpec::Core::RakeTask.new(:integration) do |t|
    t.pattern = "spec/integration/**/*_spec.rb"
    t.rspec_opts = %w(--format documentation --color)
  end

  desc "Run unit and functional tests for each BOSH component gem"
  task :unit do
    builds = Dir['*'].select {|f| File.directory?(f) && File.exists?("#{f}/spec")}
    builds -= ['bat']

    builds.each do |build|
      puts "-----#{build}-----"
      system("cd #{build} && bundle exec rspec spec") || raise("#{build} failed to build unit tests")
    end
  end

  namespace :system do
    desc "Run AWS system-wide suite"
    RSpec::Core::RakeTask.new(:aws) do |t|
      t.pattern = "spec/system/aws/**/*_spec.rb"
      t.rspec_opts = %w(--format documentation --color)
    end
  end
end

desc "Run unit, integration, and AWS system specs"
task :spec => ["spec:unit", "spec:integration", "spec:system:aws"]
