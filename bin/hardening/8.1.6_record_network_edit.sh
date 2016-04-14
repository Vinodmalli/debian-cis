#!/bin/bash

#
# CIS Debian 7 Hardening
# Authors : Thibault Dewailly, OVH <thibault.dewailly@corp.ovh.com>
#

#
# 8.1.6 Record Events That Modify the System's Network Environment (Scored)
#

set -e # One error, it's over
set -u # One variable unset, it's over

AUDIT_PARAMS='-a exit,always -F arch=b64 -S sethostname -S setdomainname -k system-locale
-a exit,always -F arch=b32 -S sethostname -S setdomainname -k system-locale
-w /etc/issue -p wa -k system-locale
-w /etc/issue.net -p wa -k system-locale
-w /etc/hosts -p wa -k system-locale
-w /etc/network -p wa -k system-locale'
FILE='/etc/audit/audit.rules'

# This function will be called if the script status is on enabled / audit mode
audit () {
    IFS=$'\n'
    for AUDIT_VALUE in $AUDIT_PARAMS; do
        debug "$AUDIT_VALUE must be in file $FILE"
        does_pattern_exists_in_file $FILE $AUDIT_VALUE
        if [ $FNRET != 0 ]; then
            crit "$AUDIT_VALUE is not in file $FILE"
        else
            ok "$AUDIT_VALUE present in $FILE"
        fi
    done
}

# This function will be called if the script status is on enabled mode
apply () {
    IFS=$'\n'
    for AUDIT_VALUE in $AUDIT_PARAMS; do
        debug "$AUDIT_VALUE must be in file $FILE"
        does_pattern_exists_in_file $FILE $AUDIT_VALUE
        if [ $FNRET != 0 ]; then
            warn "$AUDIT_VALUE is not in file $FILE, adding it"
            add_end_of_file $FILE $AUDIT_VALUE
            eval $(pkill -HUP -P 1 auditd)
        else
            ok "$AUDIT_VALUE present in $FILE"
        fi
    done
}

# This function will check config parameters required
check_config() {
    :
}

# Source Root Dir Parameter
if [ ! -r /etc/default/cis-hardenning ]; then
    echo "There is no /etc/default/cis-hardenning file, cannot source CIS_ROOT_DIR variable, aborting"
    exit 128
else
    . /etc/default/cis-hardenning
    if [ -z $CIS_ROOT_DIR ]; then
        echo "No CIS_ROOT_DIR variable, aborting"
    fi
fi 

# Main function, will call the proper functions given the configuration (audit, enabled, disabled)
[ -r $CIS_ROOT_DIR/lib/main.sh ] && . $CIS_ROOT_DIR/lib/main.sh
