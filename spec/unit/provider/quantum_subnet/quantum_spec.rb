require 'puppet'
require 'spec_helper'
require 'puppet/provider/quantum_subnet/quantum'

provider_class = Puppet::Type.type(:quantum_subnet).provider(:quantum)

describe provider_class do

  let :subnet_name do
    'net1'
  end

  let :subnet_attrs do
    {
      :name            => subnet_name,
      :ensure          => 'present',
      :cidr            => '10.0.0.0/24',
      :ip_version      => '4',
      :gateway_ip      => '10.0.0.1',
      :enable_dhcp     => 'False',
      :network_name    => 'net1',
      :tenant_id       => '',
    }
  end

  describe 'when updating a subnet' do
    let :resource do
      Puppet::Type::Quantum_subnet.new(subnet_attrs)
    end

    let :provider do
      provider_class.new(resource)
    end

    it 'should call subnet-update to change gateway_ip' do
      provider.expects(:auth_quantum).with('subnet-update',
                                           '--gateway-ip=10.0.0.2',
                                           subnet_name)
      provider.gateway_ip=('10.0.0.2')
    end

    it 'should call subnet-update to change enable_dhcp' do
      provider.expects(:auth_quantum).with('subnet-update',
                                           '--enable-dhcp=True',
                                           subnet_name)
      provider.enable_dhcp=('True')
    end

  end

end
