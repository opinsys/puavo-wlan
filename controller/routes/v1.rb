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

module PuavoWlanController
  module Routes
    module V1

      PREFIX = '/v1'

      def self.registered(app)

        status_route = "#{PREFIX}/status/:hostname"

        put_status = lambda do
          body     = request.body.read
          data     = JSON.parse(body)
          hostname = params[:hostname]

          TEMPSTORE.update_status(hostname, data)
          { :ping_interval_seconds => PING_INTERVAL_SECONDS }.to_json
        end

        delete_status = lambda do
          hostname = params[:hostname]

          TEMPSTORE.delete_status(hostname)
          nil
        end

        get_index = lambda do
          content_type 'text/html'

          erb :v1_index, :locals => {
            :status_route => status_route,
          }
        end

        app.delete(status_route, &delete_status)

        app.get("#{PREFIX}",     &get_index)
        app.get("#{PREFIX}/",    &get_index)

        app.put(status_route,    &put_status)

      end

    end
  end
end