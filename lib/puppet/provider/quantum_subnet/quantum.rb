require File.join(File.dirname(__FILE__), '..','..','..',
                  'puppet/provider/quantum')

Puppet::Type.type(:quantum_subnet).provide(
  :quantum,
  :parent => Puppet::Provider::Quantum
) do
  desc <<-EOT
    Quantum provider to manage quantum_subnet type.

    Assumes that the quantum service is configured on the same host.
  EOT

  commands :quantum => 'quantum'

  mk_resource_methods

  def self.quantum_type
    'subnet'
  end

  def self.instances
    list_quantum_resources(quantum_type).collect do |id|
      attrs = get_quantum_resource_attrs(quantum_type, id)
      new(
        :ensure                    => :present,
        :name                      => attrs['name'],
        :id                        => attrs['id'],
        :cidr                      => attrs['cidr'],
        :ip_version                => attrs['ip_version'],
        :gateway_ip                => attrs['gateway_ip'],
        :allocation_pools          => attrs['allocation_pools'],
        :host_routes               => attrs['host_routes'],
        :dns_nameservers           => attrs['dns_nameservers'],
        :enable_dhcp               => attrs['enable_dhcp'],
        :network_id                => attrs['network_id'],
        :tenant_id                 => attrs['tenant_id']
      )
    end
  end

  def self.prefetch(resources)
    subnets = instances
    resources.keys.each do |name|
      if provider = subnets.find{ |subnet| subnet.name == name }
        resources[name].provider = provider
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    opts = ["--name=#{@resource[:name]}"]

    if @resource[:ip_version]
      opts << "--ip-version=#{@resource[:ip_version]}"
    end

    if @resource[:gateway_ip]
      opts << "--gateway-ip=#{@resource[:gateway_ip]}"
    end

    if @resource[:enable_dhcp]
      opts << "--enable-dhcp=#{@resource[:enable_dhcp]}"
    end

    if @resource[:tenant_name]
      tenant_id = self.class.get_tenant_id(model.catalog,
                                           @resource[:tenant_name])
      opts << "--tenant_id=#{tenant_id}"
    elsif @resource[:tenant_id]
      opts << "--tenant_id=#{@resource[:tenant_id]}"
    end

    if @resource[:network_name]
      opts << resource[:network_name]
    elsif @resource[:network_id]
      opts << resource[:network_id]
    end

    results = auth_quantum('subnet-create', '--format=shell',
                           opts, resource[:cidr])

    if results =~ /Created a new subnet:/
      attrs = self.class.parse_creation_output(results)
      @property_hash = {
        :ensure                    => :present,
        :name                      => resource[:name],
        :id                        => attrs['id'],
        :cidr                      => attrs['cidr'],
        :ip_version                => attrs['ip_version'],
        :gateway_ip                => attrs['gateway_ip'],
        :allocation_pools          => attrs['allocation_pools'],
        :host_routes               => attrs['host_routes'],
        :dns_nameservers           => attrs['dns_nameservers'],
        :enable_dhcp               => attrs['enable_dhcp'],
        :network_id                => attrs['network_id'],
        :tenant_id                 => attrs['tenant_id'],
      }
    else
      fail("did not get expected message on subnet creation, got #{results}")
    end
  end

  def destroy
    auth_quantum('subnet-delete', name)
    @property_hash[:ensure] = :absent
  end

  def gateway_ip=(value)
    auth_quantum('subnet-update', "--gateway-ip=#{value}", name)
  end

  def enable_dhcp=(value)
    auth_quantum('subnet-update', "--enable-dhcp=#{value}", name)
  end

  [
   :cidr,
   :ip_version,
   :network_id,
   :tenant_id,
  ].each do |attr|
     define_method(attr.to_s + "=") do |value|
       fail("Property #{attr.to_s} does not support being updated")
     end
  end

end
