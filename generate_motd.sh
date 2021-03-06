#!/usr/local/bin/bash 
# Script name:	generate_motd.sh
# Version:      v4.07.160410
# Created on:   10/02/2014
# Author:       Willem D'Haese
# Purpose:      Bash script that will dynamically generate a message
#               of they day for users logging in.
# On GitHub:    https://github.com/willemdh/generate_motd
# On OutsideIT: https://outsideit.net/generate-motd
# Recent History:
#   22/02/16 => Added which ip
#   03/03/16 => Fun with colortest
#   03/04/16 => Apt-get count fix
#   09/04/16 => Check if yum before rpm check
#   10/04/16 => Sed for Raspbian OS version and Pi platform
# Copyright:
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version. This program is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
# Public License for more details. You should have received a copy of the
# GNU General Public License along with this program.  If not, see
# <http://www.gnu.org/licenses/>.

Verbose=1

WriteLog () {
    if [ -z "$1" ] ; then
        echo "WriteLog: Log parameter #1 is zero length. Please debug..."
        exit 1
    else
        if [ -z "$2" ] ; then
            echo "WriteLog: Severity parameter #2 is zero length. Please debug..."
            exit 1
        else
            if [ -z "$3" ] ; then
                echo "WriteLog: Message parameter #3 is zero length. Please debug..."
                exit 1
            fi
        fi
    fi
    Now=$(date '+%Y-%m-%d %H:%M:%S,%3N')
    FullScriptName="${BASH_SOURCE[0]}"
    ScriptName=$(basename "$FullScriptName")
    if [ "${1,,}" = "verbose" -a $Verbose = 1 ] ; then
        echo "$Now: $ScriptName: $2: $3"
    elif [ "${1,,}" = "verbose" -a $Verbose = 0 ] ; then
        :
    elif [ "${1,,}" = "output" ] ; then
        echo "${Now}: $ScriptName: $2: $3"
    elif [ -f $1 ] ; then
        echo "${Now}: $ScriptName: $2: $3" >> $1
    fi
}

CountUpdates () {
    if [[ -x "/usr/bin/yum" ]] ; then
        UpdateCount=$(/usr/bin/yum -d 0 check-update 2>/dev/null | echo $(($(wc -l)-1)))
        if [ $UpdateCount == -1 ]; then
            UpdateCount=0
        fi
    elif [[ -x "/usr/bin/zypper" ]] ; then
        UpdateCount=$(zypper list-updates | wc -l) 
        UpdateCount=$(expr $UpdateCount - 4)
	    if (( $UpdateCount <= 0 )) ; then
	        UpdateCount=0
	    fi
    elif [[ -x "/usr/bin/apt-get" ]] ; then
        UpdateCount=$(apt-get update > /dev/null; apt-get upgrade -u -s | grep -P "^Inst" | wc -l)
        if (( $UpdateCount <= 0 )) ; then
	        UpdateCount=0
	    fi
    elif [[ -x "/usr/sbin/pkg" ]] ; then
        UpdateCount=$(pkg update > /dev/null; pkg version|grep -v "=" | wc -l)
    fi
        if (( $UpdateCount <= 0 )) ; then
	        UpdateCount=0
	    fi

    echo "$UpdateCount" > /tmp/updatecount.txt
}

ColorTest () {
#   for code in {0..255}; do echo -n -e "\e[38;05;${code}m" ; echo -n -e "   ## \\\e[38;05;${code}m ##   " ; done
    string="Lientje"
    run=1
    for code1 in {1..16}; do
    #   code=`expr $run \* $code1`
    #   WriteLog Verbose Info "Code1: $code1, Code: $code, Run: $run"
    #   echo -n -e "\e[38;05;${code}m ##\\\e[38;05;${code}m## "
        for code2 in {1..16}; do
            code=`expr $code1 \+ $code2`
            echo -e "\e[38;05;${code}m ##\\\e[38;05;${code}m## "
        done 
        run=$((run + 1))
    done

}

GatherInfo () {
    CountUpdates
    ScriptName="$0"
    ScriptVersion=" $(cat $ScriptName | grep "# Version:" | awk {'print $3'} | tr -cd '[[:digit:].-]' | sed 's/.\{2\}$//') "
    OsVersion="$(freebsd-version)"
    if [[ "$OsVersion" == "SUSE"* ]] ; then
        OsVersion="$(echo $OsVersion | sed 's/ (.*//')"
        PatchLevel="$(cat /etc/*release | sed -n 3p | sed 's/.*= //')"
        OsVersion="${OsVersion}.$PatchLevel"
    elif [[ "$OsVersion" == "openSUSE"* ]] ; then
	OsVersion="$(cat /etc/os-release | sed -n 4p | sed 's/PRETTY_NAME="//' | sed 's/ (.*//')"
    elif [[ "$OsVersion" == *"Raspbian"* ]] ; then
        OsVersion="$(cat /etc/*release | head -n 1 | sed 's/.*"\(.*\)"[^"]*$/\1/')"
    fi
    IpPath="$(which ip 2>/dev/null)"
    IpAddress="$(ifconfig em0|grep inet|cut -d " " -f 2|head -1)"
    Kernel="$(uname -rs)"
    Uptime="$(uptime)"
#    UptimeDays=$(uptime| cut -d " " -f 4)
#    UptimeHours=$(uptime| cut -d " " -f 6|cut -d ":" -f 1)
#    UptimeMinutes=$(uptime| cut -d " " -f 6|cut -d ":" -f 2|cut -d "," -f 1)
#    UptimeSeconds=21
    Dmi="$(dmesg | grep "Hypervisor:"|tail -1)"
    if [[ "$Dmi" = *"QEMU"* ]] ; then
        Platform="$(dmesg | grep "Hypervisor:" | sed 's/^.*QEMU/QEMU/' | sed 's/, B.*//')"
    elif [[ "$Dmi" = *"VMware"* ]] ; then
        Platform="$(dmesg | grep "Hypervisor:" | head -1 | sed 's/^.*VMware\"/VMware/' | sed 's/, B.*//')"
    elif [[ "$Dmi" = *"FUJITSU PRIMERGY"* ]] ; then
        Platform="$(dmesg | grep "Hypervisor:" | sed 's/^.*FUJITSU PRIMERGY/Fujitsu Primergy/' | sed 's/, B.*//')"
    elif [[ "$Dmi" = *"VirtualBox"* ]] ; then
        Platform="$(dmesg | grep "Hypervisor:" | sed 's/^.*VirtualBox/VirtualBox/' | sed 's/ .*//')"
    else
        Dmi="$(dmesg | grep "Rasp")"
        if [[ "$Dmi" = *"Rasp"* ]] ; then
            Platform="$(dmesg | grep "Rasp" | sed 's/.*: //')"
        else
            Platform="Unknown"
        fi
    fi
    CpuUtil="$(printf "%0.2f\n" $(bc -q <<< scale=2\;$(uptime|cut -d ":" -f 4|cut -d "," -f 1)/$(sysctl hw | egrep 'hw.ncpu'|cut -d " " -f 2)))"
    CpuProc="$(sysctl hw | egrep 'hw.ncpu'|cut -d " " -f 2)"
    CpuLoad="$(uptime | grep -ohe '[s:][: ].*' | awk '{ print "1m: "$2 " 5m: "$3 " 15m: " $4}')"
    #MemFreeB="$(cat /proc/meminfo | grep MemFree | awk {'print $2'})"
    #MemTotalB="$(cat /proc/meminfo | grep MemTotal | awk {'print $2'})"
    #MemUsedB="$(expr $MemTotalB - $MemFreeB)"
    #MemFree="$(printf "%0.2f\n" $(bc -q <<< scale=2\;$MemFreeB/1024/1024))"
    #MemUsed="$(printf "%0.2f\n" $(bc -q <<< scale=2\;$MemUsedB/1024/1024))"
    MemTotal="$(freecolor -m -t)"
    #SwapFreeB="$(cat /proc/meminfo | grep SwapFree | awk {'print $2'})"
    #SwapTotalB="$(cat /proc/meminfo | grep SwapTotal | awk {'print $2'})"
    #SwapUsedB="$(expr $SwapTotalB - $SwapFreeB)"
    #SwapFree="$(printf "%0.2f\n" $(bc -q <<< scale=2\;$SwapFreeB/1024/1024))"
    #SwapUsed="$(printf "%0.2f\n" $(bc -q <<< scale=2\;$SwapUsedB/1024/1024))"
    #SwapTotal="$(printf "%0.2f\n" $(bc -q <<< scale=2\;$SwapTotalB/1024/1024))"
    RootFreeB="$(df -kP / | tail -1 | awk '{print $4}')"
    RootUsedB="$(df -kP / | tail -1 | awk '{print $3}')"
    RootTotalB="$(df -kP / | tail -1 | awk '{print $2}')"
    RootFree="$(printf "%0.2f\n" $(bc -q <<< scale=2\;$RootFreeB/1024/1024))"
    RootUsed="$(printf "%0.2f\n" $(bc -q <<< scale=2\;$RootUsedB/1024/1024))"
    RootTotal="$(printf "%0.2f\n" $(bc -q <<< scale=2\;$RootTotalB/1024/1024))"
    RootUsedPerc="$(df -kP / | tail -1 | awk '{print $5}'| sed s'/%$//')"
    RootFreePerc="$(expr 100 - $RootUsedPerc)" 
    UpdateCount="$(cat /tmp/updatecount.txt)"
    SessionCount="$(who | cut -d " " -f 1|uniq -c | sort -bgr)"
    ProcessCount="$(ps -Afl | wc -l)"
    ProcessMax="$(ulimit -u)"
    PhpVersion="$(/usr/bin/php -v 2>/dev/null | grep -oE '^PHP\s[0-9]+\.[0-9]+\.[0-9]+' | awk '{ print $2}')"
    MaxLeftOverChars=35
    Hostname="$(hostname)"
    HostChars=$((${#Hostname} + 8))
    LeftoverChars=$((MaxLeftOverChars - HostCHars -10))
    if [[ -x "/usr/bin/yum" ]] ; then
        UpdateType="yum"
    elif [[ -x "/usr/bin/zypper" ]] ; then
        UpdateType="zypper"
    elif [[ -x "/usr/bin/apt-get" ]] ; then
        UpdateType="apt-get"
    elif [[ -x "/usr/sbin/pkg" ]] ; then
        UpdateType="pkg"
    fi   
    WriteLog Verbose Info "UpdateType: $UpdateType"
    HttpdPath="$(which httpd 2>/dev/null)"
    WriteLog Verbose Info "HttpdPath: $HttpdPath"
    if [[ ! -z $HttpdPath ]] ; then
        HttpdVersion="$(${HttpdPath} -v | grep "Server version" | sed -e 's/.*[^0-9]\([0-9].[0-9]\+.[0-9]\+\)[^0-9]*$/\1/')"
        WriteLog Verbose Info "HttpdVersion: $HttpdVersion"
    fi
    case $UpdateType in
        "yum" )
            MariadbVersion="$(rpm -qa | grep mariadb-server | sed 's/.*-\(\([0-9]\+\.[0-9]\+\.[0-9]\+-[0-9]\+\)\).*/\1/')"
            WriteLog Verbose Info "MariadbVersion: $MariadbVersion" ;;
        "pkg" )
            WriteLog Verbose Info "Update Type $UpdateType" ;;
        *) WriteLog Verbose Info "$UpdateType not yet supported." ;;
    esac
}

StartBlueTheme () {
    # Blue
    Sch1="\e[0;34m####"
    # Light Blue
    Sch2="\e[1;34m#####"
    # Light Cyan
    Sch3="\e[1;36m#####"
    # Cyan
    Sch4="\e[0;36m#####"
    # Pre-Host Scheme
    PrHS=$Sch1$Sch1$Sch2$Sch2
    # Host Scheme Top
    HST="\e[1;36m`head -c $HostChars /dev/zero|tr '\0' '#'`"
    # Host Scheme Top Filler
    HSF="\e[1;36m###"
    # Host Scheme Bot
    HSB="\e[1;34m`head -c $HostChars /dev/zero|tr '\0' '#'`"
    # Post Host Scheme
    PHS="\e[1;34m`head -c $LeftoverChars /dev/zero|tr '\0' '#'`"
    # Host Version Filler
    HVF="\e[1;34m`head -c 9 /dev/zero|tr '\0' '#'`"
    # Front Scheme
    FrS="\e[0;34m##"
    # Equal Scheme
    ES="\e[1;34m="
    # 16 Color Green Value Scheme
    # Host Color
    HC="\e[1;32m"
    # Green Value Color
    VC="\e[0;32m"
    # Light Green Value Color
    VCL="\e[1;32m"
    # Light Yellow Key Color
    KS="\e[1;33m"
    # Version Color
    SVC="\e[1;36m"
}

StartRedTheme () {
    # Red
    Sch1="\e[0;31m####"
    # Light Red
    Sch2="\e[1;31m#####"
    # Light Yellow
    Sch3="\e[1;33m#####"
    # Yellow
    Sch4="\e[0;33m#####"
    # Pre-Host Scheme
    PrHS=$Sch1$Sch1$Sch2$Sch2
    # Host Scheme Top
    HST="\e[1;33m`head -c $HostChars /dev/zero|tr '\0' '#'`"
    # Host Scheme Top Filler
    HSF="\e[1;33m###"
    # Host Scheme Bot
    HSB="\e[0;31m`head -c $HostChars /dev/zero|tr '\0' '#'`"
    # Post Host Scheme
    PHS="\e[2;31m`head -c $LeftoverChars /dev/zero|tr '\0' '#'`"
    # Host Version Filler
    HVF="\e[2;31m`head -c 9 /dev/zero|tr '\0' '#'`"
    # Front Scheme
    FrS="\e[0;31m##"
    # Equal Scheme
    ES="\e[1;31m="
    # 16 Color Yellow Value Scheme
    # Host Color
    HC="\e[1;37m"
    # Yellow Value Color
    VC="\e[0;33m"
    # Light Yellow Value Color
    VCL="\e[1;33m"
    # Light Yellow Key Color
    KS="\e[0;37m"
    # Version Color
    SVC="\e[1;33m"
}

StartOriginalBlue () {
    for i in {18..21} {21..18} ; do ShortBlueScheme+="\e[38;5;${i}m#\e[0m"  ; done ;
    for i in {17..21} {21..17} ; do BlueScheme+="\e[38;5;${i}m#\e[0m\e[38;5;${i}m#\e[0m"  ; done ;
    for i in {17..21} {21..17} ; do LongBlueScheme+="\e[38;5;${i}m#\e[0m\e[38;5;${i}m#\e[0m\e[38;5;${i}m#"  ; done ;
}

GenerateOriginal256Color () {
    Space=""
    if [[ "$Theme" == "Modern" ]] ; then
        Space="                              "
        Fto="  "
    else
        Fto="##"
    fi
    echo -e "$BlueScheme$LongBlueScheme$BlueScheme$ShortBlueScheme
$BlueScheme \e[38;5;93m $Hostname $BlueScheme $Space\e[38;5;98m$ScriptVersion
$BlueScheme$LongBlueScheme$BlueScheme$ShortBlueScheme
\e[0;38;5;17m$Fto          \e[38;5;39mIp \e[38;5;93m= \e[38;5;33m$IpAddress
\e[0;38;5;17m$Fto     \e[38;5;39mRelease \e[38;5;93m= \e[38;5;27m$OsVersion
\e[0;38;5;17m$Fto      \e[38;5;39mKernel \e[38;5;93m= \e[38;5;27m$Kernel
\e[0;38;5;17m$Fto    \e[38;5;39mPlatform \e[38;5;93m= \e[38;5;27m$Platform
\e[0;38;5;17m$Fto      \e[38;5;39mUptime \e[38;5;93m= \e[38;5;33m${Uptime} 
\e[0;38;5;17m$Fto   \e[38;5;39mCPU Usage \e[38;5;93m= \e[38;5;33m${CpuUtil}\e[38;5;27m% average CPU usage over \e[38;5;33m$CpuProc \e[38;5;27mcore(s)
\e[0;38;5;17m$Fto    \e[38;5;39mCPU Load \e[38;5;93m= \e[38;5;27m$CpuLoad
\e[0;38;5;17m$Fto      \e[38;5;39mMemory \e[38;5;93m= \e[0;30m
${MemTotal}
\e[0;38;5;17m$Fto        \e[38;5;39mRoot \e[38;5;93m= \e[38;5;27mFree: \e[38;5;33m${RootFree}\e[38;5;27mGB (\e[38;5;33m$RootFreePerc\e[38;5;27m%), Used: \e[38;5;33m${RootUsed}\e[38;5;27mGB (\e[38;5;33m$RootUsedPerc\e[38;5;27m%), Total: \e[38;5;33m${RootTotal}\e[38;5;27mGB
\e[0;38;5;17m$Fto     \e[38;5;39mUpdates \e[38;5;93m= \e[38;5;33m$UpdateCount\e[38;5;27m ${UpdateType} updates available
\e[0;38;5;17m$Fto    \e[38;5;39mSessions \e[38;5;93m= \e[38;5;33m$SessionCount\e[38;5;27m sessions
\e[0;38;5;17m$Fto   \e[38;5;39mProcesses \e[38;5;93m= \e[38;5;33m$ProcessCount\e[38;5;27m running processes of \e[38;5;33m$ProcessMax\e[38;5;27m maximum processes"
    if [[ $PhpVersion =~ ^[0-9.]+$ ]] ; then
        echo -e "\e[0;38;5;17m$Fto         \e[38;5;39mPHP \e[38;5;93m= \e[38;5;27mVersion: \e[38;5;33m$PhpVersion"
    fi
    if [[ $HttpdVersion =~ ^[0-9.]+$ ]] ; then
        echo -e "\e[0;38;5;17m$Fto      \e[38;5;39mApache \e[38;5;93m= \e[38;5;27mVersion: \e[38;5;33m$HttpdVersion"
    fi
    if [[ $MariadbVersion =~ ^[0-9.-]+$ ]] ; then
        echo -e "\e[0;38;5;17m$Fto     \e[38;5;39mMariaDB \e[38;5;93m= \e[38;5;27mVersion: \e[38;5;33m$MariadbVersion"
    fi
    echo -e "$BlueScheme$LongBlueScheme$BlueScheme$ShortBlueScheme\e[0;37m"
}

GenerateBasic16Color () {
    echo -e "$PrHS$Sch2$HST$Sch2$PHS$Sch1
$PrHS$Sch3$HSF $HC$Hostname $HSF$Sch3$HSF$HVF$SVC$ScriptVersion$Sch1
$PrHS$Sch2$HST$Sch2$PHS$Sch1
$FrS          ${KS}Ip $ES ${VCL}$IpAddress
$FrS     ${KS}Release $ES ${VC}$OsVersion
$FrS      ${KS}Kernel $ES ${VC}$Kernel
$FrS    ${KS}Platform $ES ${VC}$Platform
$FrS      ${KS}Uptime $ES ${VCL}${UptimeDays} ${VC}day(s). ${VCL}${UptimeHours}${VC}:${VCL}${UptimeMinutes}${VC}:${VCL}${UptimeSeconds}
$FrS   ${KS}CPU Usage $ES ${VCL}$CpuUtil ${VC}% average CPU usage over ${VCL}${CpuProc}${VC} core(s)
$FrS    ${KS}CPU Load $ES ${VC}$CpuLoad
$FrS      ${KS}Memory $ES ${VC}Free: ${VCL}${MemFree}${VC} GB, Used: ${VCL}${MemUsed}${VC} GB, Total: ${VCL}${MemTotal}${VC} GB
$FrS        ${KS}Swap $ES ${VC}Free: ${VCL}${SwapFree}${VC} GB, Used: ${VCL}${SwapUsed}${VC} GB, Total: ${VCL}${SwapTotal}${VC} GB
$FrS        ${KS}Root $ES ${VC}Free: ${VCL}${RootFree}${VC} GB (${VCL}$RootFreePerc${VC}%), Used: ${VCL}${RootUsed}${VC} GB (${VCL}$RootUsedPerc${VC}%), Total: ${VCL}${RootTotal}${VC} GB
$FrS     ${KS}Updates $ES ${VCL}$UpdateCount${VC} ${UpdateType} updates available.
$FrS    ${KS}Sessions $ES ${VCL}$SessionCount ${VC}sessions
$FrS   ${KS}Processes $ES ${VCL}$ProcessCount ${VC}running processes of ${VCL}$ProcessMax ${VC}maximum processes"
    if [[ $PhpVersion =~ ^[0-9.]+$ ]] ; then
        echo -e "$FrS    ${KS}PHP Info $ES ${VC}Version: ${VCL}$PhpVersion"
    fi
    if [[ $HttpdVersion =~ ^[0-9.]+$ ]] ; then
        echo -e "$FrS${KS} Apache Info $ES ${VC}Version: ${VCL}$HttpdVersion"
    fi
    echo -e "$PrHS$Sch2$HSB$Sch2$PHS$Sch1\e[0;37m"
}

GenerateHtmlTheme () {
#     echo -e "<!doctype html><html lang="en"><head><meta charset="utf-8"><title>Generate MotD</title><meta name="description" content="Generates a HTML MotD message"><meta name="author" content="OutsideIT"><link rel="stylesheet" href="css/styles.css?v=1.0"></head><body><script src="js/scripts.js"></script><p>test</p><table><thead><tr><th>Hostname</th><th>Head2</th></tr></thead><tbody><tr><td>Bla</td><td>Bla</td></tr></tbody><tfoot><tr><td></td></tr></tfoot></table></body></html>"
# TODO => Put all html into variable and ouput at end. Integrate CSS.
HtmlCode='<!doctype html><html lang="en"><head><meta charset="utf-8"><title>Generate MotD</title><meta name="description" content="Generates a HTML MotD message"><meta name="author" content="OutsideIT"><style type="text/css">'
HtmlCode+="h1 {
	font-family: Verdana;
	font-weight: normal;
	color: #024457;
	font-weight: bold;
        padding-left:30px;
}
table a:link {
	color: #666;
	font-weight: bold;
	text-decoration:none;
}
table a:visited {
	color: #999999;
	font-weight:bold;
	text-decoration:none;
}
table a:active,
table a:hover {
	color: #bd5a35;
	text-decoration:underline;
}
table {
	font-family:Arial, Helvetica, sans-serif;
	color:#666;
	font-size:12px;
	text-shadow: 1px 1px 0px #fff;
	background:#eaebec;
	margin:35px;
	width:80%;
	height:100%
	border:#ccc 3px solid;
 	-moz-border-radius:3px;
	-webkit-border-radius:3px;
	border-radius:3px;
	-moz-box-shadow: 0 1px 2px #d1d1d1;
	-webkit-box-shadow: 0 1px 2px #d1d1d1;
	box-shadow: 0 1px 2px #d1d1d1;
}
table th {
	padding:12px 25px 12px 25px;
	border-top:2px solid #fafafa;
	border-bottom:2px solid #e0e0e0;
	font-size:22px;
        font-weight:bold;
	background: #ededed;
	background: -webkit-gradient(linear, left top, left bottom, from(#ededed), to(#ebebeb));
	background: -moz-linear-gradient(top,  #ededed,  #ebebeb);
}
table th:first-child {
	text-align: left;
	padding-left:20px;
}
table tr:first-child th:first-child {
	-moz-border-radius-topleft:3px;
	-webkit-border-top-left-radius:3px;
	border-top-left-radius:3px;
}
table tr:first-child th:last-child {
	-moz-border-radius-topright:3px;
	-webkit-border-top-right-radius:3px;
	border-top-right-radius:3px;
}
table tr {
	text-align: left;
	padding-left: 20px;
}
table td:first-child {
	text-align: left;
	padding-left:20px;
	border-left: 0;
}
table td {
	padding: 8px;
	border-top: 1px solid #ffffff;
	border-bottom: 1px solid #e0e0e0;
	border-left: 2px solid #e0e0e0;

	background: #fafafa;
	background: -webkit-gradient(linear, left top, left bottom, from(#fbfbfb), to(#fafafa));
	background: -moz-linear-gradient(top,  #fbfbfb,  #fafafa);
}
table tr.even td {
	background: #f6f6f6;
	background: -webkit-gradient(linear, left top, left bottom, from(#f8f8f8), to(#f6f6f6));
	background: -moz-linear-gradient(top,  #f8f8f8,  #f6f6f6);
}
table tr:last-child td {
	border-bottom:0;
}
table tr:last-child td:first-child {
	-moz-border-radius-bottomleft:3px;
	-webkit-border-bottom-left-radius:3px;
	border-bottom-left-radius:3px;
}
table tr:last-child td:last-child {
	-moz-border-radius-bottomright:3px;
	-webkit-border-bottom-right-radius:3px;
	border-bottom-right-radius:3px;
}
table tr:hover td {
	background: #f2f2f2;
	background: -webkit-gradient(linear, left top, left bottom, from(#f2f2f2), to(#f0f0f0));
	background: -moz-linear-gradient(top,  #f2f2f2,  #f0f0f0);	
}
.strong {
   	font-weight: bold; 
}
.em {
	font-style: italic; 
}
.right {
	text-align: right;
}


"
HtmlCode+="</style></head>"
HtmlCode+="<body><script src=\"js/scripts.js\"></script><h1>System Overview - $Hostname</h1>"
HtmlCode+="<table><thead><th>$Hostname</th><th class=\"right\">$ScriptVersion</th></thead>"
HtmlCode+="<tr><td>Ip</td><td>$IpAddress</td></tr>"
HtmlCode+="<tbody><tr><td>Operating System</td><td>$OsVersion</td></tr>"
HtmlCode+="<tr><td>Kernel</td><td>$Kernel</td></tr>"
HtmlCode+="<tr><td>Platform</td><td>$Platform</td></tr>"
HtmlCode+="<tr><td>Uptime</td><td>${UptimeDays} day(s). ${UptimeHours}:${UptimeMinutes}:${UptimeSeconds}</td></tr>"

HtmlCode+="</tbody></table></body></html>"

echo $HtmlCode


}

while :; do
    case "$1" in
        -h|--help)
            DisplayHelp="true" ; shift ;;
            yum|YUM|Yum|Zypper|zypper|-U|--Updates|-Y);;
        -t|--Theme)
            shift; Theme=$1 
            case "$Theme" in
		original|Original) GatherInfo ; StartOriginalBlue ; GenerateOriginal256Color ;;
		modern|Modern) GatherInfo ; GenerateOriginal256Color ;;
		red|Red) GatherInfo ; StartRedTheme ; GenerateBasic16Color ;;
                blue|Blue) GatherInfo ; StartBlueTheme ; GenerateBasic16Color ;;
		html|Html) GatherInfo ; GenerateHtmlTheme ;;
		blank|Blank|blanco|Blanco|Text|Clean|clean) GatherInfo ; GenerateBasic16Color ;;
		*) echo "you specified a non-existant theme." ; exit 2 ;;
	    esac
            shift ;;
        -C|--Colortest) ColorTest ; shift ;;
        -*) echo "you specified a non-existant option. " ; exit 2 ;;
        *) break ;;
    esac
done

exit 0
