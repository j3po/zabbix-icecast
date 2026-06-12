#!/bin/bash

# zabbix-icecast - a template for Zabbix to gather statistics for an
# icecast2 server
#
# Copyright (C) 2010-2026 by the Contributors
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# read conf file to create the env variables
. /usr/share/zabbix/scripts/icestats.conf

SCRIPT_DIR="$(dirname "$0")"

# function definition
function load_stats {
    local max_age=$(( $(date +%s) - 30 ))

    if [[ ! -f "$STATS_TMP" ]] || [[ $(stat -c %Y "$STATS_TMP") -lt $max_age ]]; then
        if ! wget -q "$STATS_URL" -O "$STATS_TMP" \
                --http-user="$HTTP_USER" \
                --http-password="$HTTP_PASSWORD"; then
            echo "Error: failed to fetch stats from $STATS_URL" >&2
            exit 1
        fi
    fi
}

# Usage message
if [[ -z "$1" ]]; then
    echo "Usage: $0 <xsl-name> <mount>" >&2
    exit 1
fi

# Check for XSL existance
XSL_FILE="$SCRIPT_DIR/xslt/$1.xsl"
if [[ ! -f "$XSL_FILE" ]]; then
    echo "Error: XSL file not found: $XSL_FILE" >&2
    exit 1
fi

# Call function to get xml
load_stats
# Transform XML with XSL file for desired statistic value
xsltproc --stringparam mount "$2" "$XSL_FILE" "$STATS_TMP"
