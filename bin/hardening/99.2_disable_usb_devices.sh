#!/bin/bash

#
# CIS Debian 7/8 Hardening /!\ Not in the Guide
#

#
# 99.2 Disable USB Devices
#

set -e # One error, it's over
set -u # One variable unset, it's over

USER='root'
PATTERN='ACTION=="add", SUBSYSTEMS=="usb", TEST=="authorized_default", ATTR{authorized_default}="0"' # We do test disabled by default, whitelist is up to you
FILES_TO_SEARCH='/etc/udev/rules.d'
FILE='/etc/udev/rules.d/10-CIS_99.2_usb_devices.sh'

# This function will be called if the script status is on enabled / audit mode
audit () {
    SEARCH_RES=0
    for FILE_SEARCHED in $FILES_TO_SEARCH; do
        if [ $SEARCH_RES = 1 ]; then break; fi
        if test -d $FILE_SEARCHED; then
            debug "$FILE_SEARCHED is a directory"
            for file_in_dir in $(ls $FILE_SEARCHED); do
                does_pattern_exist_in_file "$FILE_SEARCHED/$file_in_dir" "^$PATTERN"
                if [ $FNRET != 0 ]; then
                    debug "$PATTERN is not present in $FILE_SEARCHED/$file_in_dir"
                else
                    ok "$PATTERN is present in $FILE_SEARCHED/$file_in_dir"
                    SEARCH_RES=1
                    break
                fi
            done
        else
            does_pattern_exist_in_file "$FILE_SEARCHED" "^$PATTERN"
            if [ $FNRET != 0 ]; then
                debug "$PATTERN is not present in $FILE_SEARCHED"
            else
                ok "$PATTERN is present in $FILES_TO_SEARCH"
                SEARCH_RES=1
            fi
        fi
    done
    if [ $SEARCH_RES = 0 ]; then
        crit "$PATTERN is not present in $FILES_TO_SEARCH"
    fi
}

# This function will be called if the script status is on enabled mode
apply () {
    SEARCH_RES=0
    for FILE_SEARCHED in $FILES_TO_SEARCH; do
        if [ $SEARCH_RES = 1 ]; then break; fi
        if test -d $FILE_SEARCHED; then
            debug "$FILE_SEARCHED is a directory"
            for file_in_dir in $(ls $FILE_SEARCHED); do
                does_pattern_exist_in_file "$FILE_SEARCHED/$file_in_dir" "^$PATTERN"
                if [ $FNRET != 0 ]; then
                    debug "$PATTERN is not present in $FILE_SEARCHED/$file_in_dir"
                else
                    ok "$PATTERN is present in $FILE_SEARCHED/$file_in_dir"
                    SEARCH_RES=1
                    break
                fi
            done
        else
            does_pattern_exist_in_file "$FILE_SEARCHED" "^$PATTERN"
            if [ $FNRET != 0 ]; then
                debug "$PATTERN is not present in $FILE_SEARCHED"
            else
                ok "$PATTERN is present in $FILES_TO_SEARCH"
                SEARCH_RES=1
            fi
        fi
    done
    if [ $SEARCH_RES = 0 ]; then
        warn "$PATTERN is not present in $FILES_TO_SEARCH"
        touch $FILE
        chmod 644 $FILE
        add_end_of_file $FILE '
# By default, disable all.
ACTION=="add", SUBSYSTEMS=="usb", TEST=="authorized_default", ATTR{authorized_default}="0"

# Enable hub devices.
ACTION=="add", ATTR{bDeviceClass}=="09", TEST=="authorized", ATTR{authorized}="1"

# Enables keyboard devices
ACTION=="add", ATTR{product}=="*[Kk]eyboard*", TEST=="authorized", ATTR{authorized}="1"

# PS2-USB converter
ACTION=="add", ATTR{product}=="*Thinnet TM*", TEST=="authorized", ATTR{authorized}="1"
'
    fi
}

# This function will check config parameters required
check_config() {
    :
}

# Source Root Dir Parameter
if [ -r /etc/default/cis-hardening ]; then
    . /etc/default/cis-hardening
fi
if [ -z "$CIS_ROOT_DIR" ]; then
     echo "There is no /etc/default/cis-hardening file nor cis-hardening directory in current environment."
     echo "Cannot source CIS_ROOT_DIR variable, aborting."
    exit 128
fi

# Main function, will call the proper functions given the configuration (audit, enabled, disabled)
if [ -r $CIS_ROOT_DIR/lib/main.sh ]; then
    . $CIS_ROOT_DIR/lib/main.sh
else
    echo "Cannot find main.sh, have you correctly defined your root directory? Current value is $CIS_ROOT_DIR in /etc/default/cis-hardening"
    exit 128
fi
