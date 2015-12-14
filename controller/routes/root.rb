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
            :total_ap_rx_bytes  => 0,
            :total_ap_tx_bytes  => 0,
            :total_sta_rx_bytes => 0,
            :total_sta_tx_bytes => 0,
          }

          TEMPSTORE.get_hosts.each do |host|
            host_accesspoints = host.fetch('accesspoints')
            host_hostname     = host.fetch('hostname')
            host_rx_bytes     = 0
            host_tx_bytes     = 0
            host_sta_count    = 0

            host_accesspoints.each do |accesspoint|
              ap_bssid      = accesspoint.fetch('bssid')
              ap_start_time = Time.parse(accesspoint.fetch('start_time'))
              ap_stations   = accesspoint.fetch('stations')
              ap_rx_bytes   = accesspoint.fetch('rx_bytes')
              ap_tx_bytes   = accesspoint.fetch('tx_bytes')
              ap_uptime     = time_now - ap_start_time

              host_sta_count                 += ap_stations.length
              host_rx_bytes                  += ap_rx_bytes
              host_tx_bytes                  += ap_tx_bytes
              erb_locals[:total_ap_rx_bytes] += ap_rx_bytes
              erb_locals[:total_ap_tx_bytes] += ap_tx_bytes

              ap_stations.each do |station|
                sta_mac                            = station.fetch('mac')
                sta_hostname, sta_fqdn, sta_ipaddr = arp_table.fetch(sta_mac, [nil, nil, nil])
                sta_rx_bytes                       = station.fetch('rx_bytes')
                sta_tx_bytes                       = station.fetch('tx_bytes')

                erb_locals[:total_sta_rx_bytes] += sta_rx_bytes
                erb_locals[:total_sta_tx_bytes] += sta_tx_bytes

                erb_locals[:stations] << {
                  :bssid          => ap_bssid,
                  :connected_time => station.fetch('connected_time'),
                  :fqdn           => sta_fqdn,
                  :hostname       => sta_hostname,
                  :ipaddr         => sta_ipaddr,
                  :mac            => sta_mac,
                  :rx_bytes       => sta_rx_bytes,
                  :tx_bytes       => sta_tx_bytes,
                }
              end
              erb_locals[:accesspoints] << {
                :bssid     => ap_bssid,
                :channel   => accesspoint.fetch('channel'),
                :hostname  => host_hostname,
                :rx_bytes  => ap_rx_bytes,
                :tx_bytes  => ap_tx_bytes,
                :ssid      => accesspoint.fetch('ssid'),
                :sta_count => ap_stations.length,
                :uptime    => ap_uptime,
              }
            end
            erb_locals[:hosts] << {
              :ap_count  => host_accesspoints.length,
              :hostname  => host_hostname,
              :state     => TEMPSTORE.get_host_state(host_hostname),
              :sta_count => host_sta_count,
              :rx_bytes  => host_rx_bytes,
              :tx_bytes  => host_tx_bytes,
              :version   => host.fetch('version'),
            }
          end

          erb :index, :locals => erb_locals
        end

        app.get("#{PREFIX}/", &root)
      end

    end
  end
end
