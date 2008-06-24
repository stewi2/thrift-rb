require 'rubygems'
require 'rake'
require 'spec/rake/spectask'

THRIFT = '../../compiler/cpp/thrift'

task :default => [:spec, :test]

Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.spec_opts = ['--color']
end

Spec::Rake::SpecTask.new(:'spec:rcov') do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.spec_opts = ['--color']
  t.rcov = true
  t.rcov_opts = ['--exclude', '^spec,/gems/']
end

desc 'Run the compiler tests (requires full thrift checkout)'
task :test do
  # ensure this is a full thrift checkout and not a tarball of the ruby libs
  cmd = 'head -1 ../../README 2>/dev/null | grep Thrift >/dev/null 2>/dev/null'
  system(cmd) or fail "rake test requires a full thrift checkout"
  sh 'make', '-C', File.dirname(__FILE__) + "/../../test/rb"
end

desc 'Compile the .thrift files for the specs'
task :'gen-rb' => [:'gen-rb:spec', :'gen-rb:benchmark']

namespace :'gen-rb' do
  task :'spec' do
    dir = File.dirname(__FILE__) + '/spec'
    sh THRIFT, '--gen', 'rb', '-o', dir, "#{dir}/ThriftSpec.thrift"
  end

  task :'benchmark' do
    dir = File.dirname(__FILE__) + '/benchmark'
    sh THRIFT, '--gen', 'rb', '-o', dir, "#{dir}/Benchmark.thrift"
  end
end

desc 'Run benchmarking of NonblockingServer'
task :benchmark do
  ruby 'benchmark/benchmark.rb'
end
