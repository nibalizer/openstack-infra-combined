require 'spec_helper_acceptance'

describe 'basic accessbot' do

  if fact('osfamily') == 'Debian'

    context 'default parameters' do

      it 'should work with no errors' do

        base_path = File.dirname(__FILE__)
        pp_path = File.join(base_path, 'fixtures', 'default.pp')
        pp = File.read(pp_path)

        # Run it twice and test for idempotency
        apply_manifest(pp, :catch_failures => true)
        apply_manifest(pp, :catch_changes => true)
      end

    end

    context 'installation of packages' do

      describe package('python-yaml') do
        it { should be_installed }
      end

    end

    context 'files and directories' do

      describe file('/etc/accessbot/accessbot.config') do
        it { should be_file }
        it { should be_owned_by 'root' }
        it { should be_mode 440 }
        it { should be_grouped_into 'accessbo' }
      end

    end

    context 'main proccess' do

      describe process("accessbot") do
        its(:user) { should eq "accessbot" }
        its(:args) { should match /-c accessbot.config/ }
      end

    end

  end

end
