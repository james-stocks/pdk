require 'spec_helper_acceptance'

describe 'pdk test unit', module_command: true do
  context 'within a module directory' do
    before(:each) do
      system('pdk new module foo --skip-interview') || raise
      Dir.chdir('foo')
    end

    after(:each) do
      Dir.chdir('..')
      FileUtils.rm_rf('foo')
    end

    describe command('pdk test unit') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match(%r{Running unit tests}) }
      its(:stderr) { is_expected.not_to match(%r{WARN|ERROR|FAIL}i) }
    end

    context 'listing tests' do
      before(:each) do
        spec_file = File.join('spec', 'demo_spec.rb')
        File.open(spec_file, 'w') do |f|
          f.puts <<-EOF
require 'spec_helper'

describe Hash do
  on_supported_os.each do |os, facts|
    context "On OS \#{os}" do
      it 'should return a blank instance' do
        Hash.new.should == {}
      end
    end
  end
end
EOF
        end
      end

      describe command('pdk test unit --list') do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match(%r{Examples:.*demo_spec.rb\[1:1:1\]}m) }
        its(:stdout) { is_expected.to match(%r{demo_spec.rb\[1:2:1\]}) }
        its(:stdout) { is_expected.to match(%r{demo_spec.rb\[1:3:1\]}) }
      end
    end

    context 'listing tests when there are none' do
      FileUtils.rm_rf('spec/*')
      describe command('pdk test unit --list') do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match(%r{No examples found}) }
      end
    end

    context 'attempting to list tests with spec code errors' do
      before(:each) do
        spec_file = File.join('spec', 'demo_spec.rb')
        File.open(spec_file, 'w') do |f|
          f.puts <<-EOF
require 'spec_helper'

describe Hash do
  on_supported_os.each do |os, facts|
    context "On OS \#{os}" # THIS LINE IS BAD
      it 'should return a blank instance' do
        Hash.new.should == {}
      end
    end
  end
end
EOF
        end
      end

      describe command('pdk test unit --list') do
        its(:stdout) { is_expected.to match(%r{Unable to enumerate examples.*SyntaxError}m) }
      end
    end
  end
end
