#!/usr/bin/env ruby1.9.1
# coding: utf-8

# = Puavo's WLAN Controller
#
# Author    :: Tuomas Räsänen <tuomasjjrasanen@tjjr.fi>
# Copyright :: Copyright (C) 2015 Opinsys Oy
# License   :: GPLv2+
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301 USA.

require 'time'

module PuavoWlanController
  module Routes
    module Root

      PREFIX = ''

      def self.registered(app)
        root = lambda do
          content_type 'text/html'

          arp_table = get_arp_table
          time_now  = Time.now

          erb_locals = {
            :accesspoints       => [],
            :hosts              => [],
            :stations           => [],
            :radios             => [],
            :total_ap_rx_bytes  => 0,
            :total_ap_tx_bytes  => 0,
            :total_ap_rx_rate   => 0,
            :total_ap_tx_rate   => 0,
            :total_sta_rx_bytes => 0,
            :total_sta_tx_bytes => 0,
            :total_sta_rx_rate  => 0,
            :total_sta_tx_rate  => 0,
          }

          TEMPSTORE.get_statuses.each do |host|
            host_hostname           = host.fetch('hostname')
            host_radios             = host.fetch('radios')
            host_rx_bytes           = 0
            host_tx_bytes           = 0
            host_rx_rate            = 0
            host_tx_rate            = 0
            host_sta_count          = 0
            host_system_start_time  = Time.parse(host.fetch('system_start_time'))
            host_service_start_time = Time.parse(host.fetch('service_start_time'))
            host_system_uptime      = time_now - host_system_start_time
            host_service_uptime     = time_now - host_service_start_time
            host_ap_count           = 0

            next if host_radios.empty?

            host_radios.each do |radio|
              radio_mac          = radio.fetch('mac')
              radio_accesspoints = radio.fetch('accesspoints')
              radio_ap_count     = radio_accesspoints.length
              radio_rx_bytes     = 0
              radio_tx_bytes     = 0
              radio_rx_rate      = 0
              radio_tx_rate      = 0
              radio_channel      = 0
              radio_tx_power     = 0
              radio_sta_count    = 0

              host_ap_count += radio_ap_count

              radio_accesspoints.each do |accesspoint|
                ap_bssid       = accesspoint.fetch('bssid')
                ap_start_time  = Time.parse(accesspoint.fetch('start_time'))
                ap_stations    = accesspoint.fetch('stations')
                ap_rx_bytes    = accesspoint.fetch('rx_bytes')
                ap_tx_bytes    = accesspoint.fetch('tx_bytes')
                ap_rx_rate     = accesspoint.fetch('rx_rate')
                ap_tx_rate     = accesspoint.fetch('tx_rate')
                ap_uptime      = time_now - ap_start_time
                radio_channel  = accesspoint.fetch('channel')
                radio_tx_power = accesspoint.fetch('tx_power_limit_dBm')

                host_sta_count                 += ap_stations.length
                host_rx_bytes                  += ap_rx_bytes
                host_tx_bytes                  += ap_tx_bytes
                host_rx_rate                   += ap_rx_rate
                host_tx_rate                   += ap_tx_rate
                radio_rx_bytes                 += ap_rx_bytes
                radio_tx_bytes                 += ap_tx_bytes
                radio_rx_rate                  += ap_rx_rate
                radio_tx_rate                  += ap_tx_rate
                erb_locals[:total_ap_rx_bytes] += ap_rx_bytes
                erb_locals[:total_ap_tx_bytes] += ap_tx_bytes
                erb_locals[:total_ap_rx_rate]  += ap_rx_rate
                erb_locals[:total_ap_tx_rate]  += ap_tx_rate
                radio_sta_count                += ap_stations.length

                ap_stations.each do |station|
                  sta_mac                            = station.fetch('mac')
                  sta_hostname, sta_fqdn, sta_ipaddr = arp_table.fetch(sta_mac, [nil, nil, nil])
                  sta_rx_bytes                       = station.fetch('rx_bytes')
                  sta_tx_bytes                       = station.fetch('tx_bytes')
                  sta_rx_rate                        = station.fetch('rx_rate')
                  sta_tx_rate                        = station.fetch('tx_rate')
                  sta_start_time                     = Time.parse(station.fetch('start_time'))
                  sta_rssi                           = station.fetch('rssi', '?')

                  erb_locals[:total_sta_rx_bytes] += sta_rx_bytes
                  erb_locals[:total_sta_tx_bytes] += sta_tx_bytes
                  erb_locals[:total_sta_rx_rate]  += sta_rx_rate
                  erb_locals[:total_sta_tx_rate]  += sta_tx_rate

                  erb_locals[:stations] << {
                    :bssid    => ap_bssid,
                    :uptime   => time_now - sta_start_time,
                    :fqdn     => sta_fqdn,
                    :hostname => sta_hostname,
                    :ipaddr   => sta_ipaddr,
                    :mac      => sta_mac,
                    :rx_bytes => sta_rx_bytes,
                    :tx_bytes => sta_tx_bytes,
                    :rx_rate  => sta_rx_rate,
                    :tx_rate  => sta_tx_rate,
                    :rssi     => sta_rssi,
                    :vendor   => get_vendor(sta_mac),
                  }
                end
                erb_locals[:accesspoints] << {
                  :radio_mac => accesspoint.fetch('radio_mac'),
                  :bssid     => ap_bssid,
                  :hostname  => host_hostname,
                  :rx_bytes  => ap_rx_bytes,
                  :rx_rate   => ap_rx_rate,
                  :tx_bytes  => ap_tx_bytes,
                  :tx_rate   => ap_tx_rate,
                  :ssid      => accesspoint.fetch('ssid'),
                  :sta_count => ap_stations.length,
                  :uptime    => ap_uptime,
                }
              end
              erb_locals[:radios] << {
                :hostname  => host_hostname,
                :driver    => radio.fetch('driver'),
                :mac       => radio_mac,
                :product   => radio.fetch('product'),
                :ap_count  => radio_ap_count,
                :rx_bytes  => radio_rx_bytes,
                :tx_bytes  => radio_tx_bytes,
                :rx_rate   => radio_rx_rate,
                :tx_rate   => radio_tx_rate,
                :channel   => radio_channel,
                :tx_power  => radio_tx_power,
                :sta_count => radio_sta_count,
                :vendor    => get_vendor(radio_mac),

              }
            end
            erb_locals[:hosts] << {
              :ap_count       => host_ap_count,
              :hostname       => host_hostname,
              :state          => TEMPSTORE.get_status_state(host_hostname),
              :sta_count      => host_sta_count,
              :system_uptime  => host_system_uptime,
              :service_uptime => host_service_uptime,
              :rx_bytes       => host_rx_bytes,
              :tx_bytes       => host_tx_bytes,
              :rx_rate        => host_rx_rate,
              :tx_rate        => host_tx_rate,
              :version        => host.fetch('version'),
              :loadavg1       => host.fetch('loadavg1'),
              :loadavg5       => host.fetch('loadavg5'),
              :loadavg15      => host.fetch('loadavg15'),
              :phy_count      => host_radios.length,
            }
          end

          erb :index, :locals => erb_locals
        end

        app.get("#{PREFIX}/", &root)
      end

    end
  end
end
