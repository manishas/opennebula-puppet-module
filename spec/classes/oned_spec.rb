require 'spec_helper'
require 'rspec-puppet'
require 'hiera'
require 'facter'

configdir = '/etc/one'
oned_config = "#{configdir}/oned.conf"
hiera_config = 'spec/fixtures/hiera/hiera.yaml'

describe 'one::oned' do
  context 'with hiera config on RedHat' do
    let(:hiera_config) { hiera_config }
    let (:facts) {{
        :osfamily => 'RedHat'
    }}
    context 'as mgmt node with sqlite' do
      let(:params) {{
          :backend => 'sqlite',
          :ldap    => false
      }}
      it { should contain_package('dbus') }
      it { should contain_package('opennebula') }
      it { should contain_package('opennebula-server') }
      it { should contain_package('opennebula-ruby') }
      it { should contain_file(oned_config).with_content(/^DB = \[ backend = \"sqlite\"/) }
      it { should contain_file('/var/lib/one').with({'owner' => 'oneadmin'}) }
    end
    context 'as mgmt node with mysql' do
      hiera = Hiera.new(:config => hiera_config)
      let(:params) {{
          :backend => 'mysql',
          :ldap    => false
      }}
      it { should contain_package('dbus') }
      it { should contain_package('opennebula') }
      it { should contain_package('opennebula-server') }
      it { should contain_package('opennebula-ruby') }
      it { should contain_file(oned_config).with_content(/^DB = \[ backend = \"mysql\"/) }
      it { should contain_file('/var/lib/one').with({'owner' => 'oneadmin'}) }
      it { should contain_file('/var/lib/one/bin/one_db_backup.sh').with_content(/mysqldump/m) }
      it { should contain_cron('one_db_backup').with({
                                                      'command' => hiera.lookup('one::oned::backup::script_path', nil, nil),
                                                      'user'    => hiera.lookup('one::oned::backup::db_user', nil, nil),
                                                      'target'  => hiera.lookup('one::oned::backup::db_user', nil, nil),
                                                      'minute'  => hiera.lookup('one::oned::backup::intervall', nil, nil),
                                                     }) }
    end
    context 'as mgmt node check hookscript rollout' do
      let(:params) {{
          :backend => 'mysql',
          :ldap    => false
      }}
      it { should contain_class('one::oned::config') }
      it { should contain_file('/usr/share/one/hooks').with({
                                                                'source' => 'puppet:///modules/one/hookscripts'
                                                            }) }
    end # fin context 'as mgmt node | as mgmt node check hookscript rollout'
  end
  context 'with hiera config on Debian' do
    let(:hiera_config) { hiera_config }
    let (:facts) {{
        :osfamily => 'Debian'
    }}
    context 'as mgmt node with sqlite' do
      let(:params) {{
          :backend => 'sqlite',
          :ldap    => false
      }}
      it { should contain_package('dbus') }
      it { should contain_package('opennebula') }
      it { should contain_package('ruby-opennebula') }
      it { should contain_file(oned_config).with_content(/^DB = \[ backend = \"sqlite\"/) }
      it { should contain_file('/var/lib/one').with({'owner' => 'oneadmin'}) }
    end
    context 'as mgmt node with mysql' do
      let(:params) {{
          :backend => 'mysql',
          :ldap    => false
      }}
      it { should contain_package('dbus') }
      it { should contain_package('opennebula') }
      it { should contain_package('ruby-opennebula') }
      it { should contain_file(oned_config).with_content(/^DB = \[ backend = \"mysql\"/) }
      it { should contain_file('/var/lib/one').with({'owner' => 'oneadmin'}) }
      it { should contain_file('/var/lib/one/bin/one_db_backup.sh').with_content(/mysqldump/m) }
      it { should contain_cron('one_db_backup') }
    end
  end

end
