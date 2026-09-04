#!/bin/sh

# LibreNMS reboot-required state-sensor extend script (prototype).
#
# Detects whether the host needs a reboot to apply a pending kernel or
# library update, across multiple distro families. Emits a bare
# 0 (no reboot needed), 1 (reboot needed), or 2 (check failed --
# unsupported distro or missing detection tool) on stdout, one line,
# no envelope -- the LibreNMS state-sensor discovery path reads this
# value directly via NET-SNMP-EXTEND-MIB::nsExtendOutLine.

ids=""
if [ -r /etc/os-release ]; then
    ids=$(. /etc/os-release 2>/dev/null; echo "$ID $ID_LIKE")
fi

case " $ids " in
    *" debian "*|*" ubuntu "*)
        # update-notifier-common/unattended-upgrades create this file.
        if [ -f /var/run/reboot-required ]; then
            echo 1
        else
            echo 0
        fi
        exit 0
        ;;
esac

case " $ids " in
    *" rhel "*|*" fedora "*|*" centos "*|*" rocky "*|*" almalinux "*|*" amzn "*)
        # yum-utils/dnf-utils. Exit 1 = reboot required, 0 = not required.
        if ! command -v needs-restarting >/dev/null 2>&1; then
            echo 2
            exit 0
        fi
        needs-restarting -r >/dev/null 2>&1
        if [ "$?" -eq 1 ]; then
            echo 1
        else
            echo 0
        fi
        exit 0
        ;;
esac

case " $ids " in
    *" suse "*)
        # zypper needs-rebooting. Exit 1 = reboot required, 0 = not required.
        if ! command -v zypper >/dev/null 2>&1; then
            echo 2
            exit 0
        fi
        zypper needs-rebooting >/dev/null 2>&1
        if [ "$?" -eq 1 ]; then
            echo 1
        else
            echo 0
        fi
        exit 0
        ;;
esac

case " $ids " in
    *" arch "*)
        # No official tool: a reboot is needed once the running kernel's
        # module directory has been replaced by a newer package upgrade.
        current_kernel=$(uname -r)
        if [ -d "/usr/lib/modules/$current_kernel" ]; then
            echo 0
        else
            echo 1
        fi
        exit 0
        ;;
esac

# unsupported distro
echo 2
