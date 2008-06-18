require 'rubygems'
require 'rake'
require 'spec/rake/spectask'

task :default => [:spec, :test]

Spec::Rake::SpecTask.new("spec") do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.spec_opts = ['--color']
end

Spec::Rake::SpecTask.new("rcov_spec") do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.spec_opts = ['--color']
  t.rcov = true
  t.rcov_opts = ['--exclude', '^spec,/gems/']
end

task :test do
  sh 'make', '-C', File.dirname(__FILE__) + "/../../test/rb"
end

task :'gen-rb' do
  thrift = '../../compiler/cpp/thrift'
  dir = File.dirname(__FILE__) + '/spec'
  sh thrift, '--gen', 'rb', '-o', dir, "#{dir}/ThriftSpec.thrift"
end
