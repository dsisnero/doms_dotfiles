# Home Assistant automation role
package "mosquitto"

# Node-RED for flow-based programming
if platform_family == "debian"
  package "node-red"
end

# Additional home automation packages can be added here
# Consider adding cookbooks for home-assistant, zigbee2mqtt, etc.
