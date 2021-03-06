# Copyright (c) 2009-2012 VMware, Inc.

module Bosh::Agent
  class Infrastructure::Openstack::Settings

    VIP_NETWORK_TYPE = "vip"
    DHCP_NETWORK_TYPE = "dynamic"
    MANUAL_NETWORK_TYPE = "manual"

    SUPPORTED_NETWORK_TYPES = [
        VIP_NETWORK_TYPE, DHCP_NETWORK_TYPE, MANUAL_NETWORK_TYPE
    ]

    AUTHORIZED_KEYS = File.join("/home/", BOSH_APP_USER, ".ssh/authorized_keys")

    def logger
      Bosh::Agent::Config.logger
    end

    def authorized_keys
      AUTHORIZED_KEYS
    end

    def setup_openssh_key
      public_key = Infrastructure::Openstack::Registry.get_openssh_key
      if public_key.nil? || public_key.empty?
        return
      end
      FileUtils.mkdir_p(File.dirname(authorized_keys))
      FileUtils.chmod(0700, File.dirname(authorized_keys))
      FileUtils.chown(Bosh::Agent::BOSH_APP_USER, Bosh::Agent::BOSH_APP_GROUP,
                      File.dirname(authorized_keys))
      File.open(authorized_keys, "w") { |f| f.write(public_key) }
      FileUtils.chown(Bosh::Agent::BOSH_APP_USER, Bosh::Agent::BOSH_APP_GROUP,
                      authorized_keys)
      FileUtils.chmod(0644, authorized_keys)
    end

    def load_settings
      setup_openssh_key
      Infrastructure::Openstack::Registry.get_settings
    end

    def get_network_settings(network_name, properties)
      type = properties["type"]
      unless type && SUPPORTED_NETWORK_TYPES.include?(type)
        raise Bosh::Agent::StateError,
              "Unsupported network type '%s', valid types are: %s" %
                  [type, SUPPORTED_NETWORK_TYPES.join(', ')]
      end

      # Nothing to do for "vip" networks
      return nil if properties["type"] == VIP_NETWORK_TYPE

      sigar = Sigar.new
      net_info = sigar.net_info
      ifconfig = sigar.net_interface_config(net_info.default_gateway_interface)

      properties = {}
      properties["ip"] = ifconfig.address
      properties["netmask"] = ifconfig.netmask
      properties["dns"] = []
      properties["dns"] << net_info.primary_dns if net_info.primary_dns &&
                                                   !net_info.primary_dns.empty?
      properties["dns"] << net_info.secondary_dns if net_info.secondary_dns &&
                                                     !net_info.secondary_dns.empty?
      properties["gateway"] = net_info.default_gateway
      properties
    end

  end
end
