#!/bin/bash
WRITE="write_test_"
READ="read_test_"
declare -A vdbench_params
declare -A log
declare -A directoryStracture
declare -A vdbenchResultsLog
declare -A vdbench
declare -A storageInfo
declare -A hostInfo

#### global variables
directoryStracture[absPath]="benchmark_results"
directoryStracture[bas]="benchmark_results"
log[timestamp]=$(date +%y%m%d_%H%M%S)
log[debug]="/tmp/vdbench.benchmark.debug.${log[timestamp]}.log"
log[verbose]="/tmp/vdbench.benchmark.verbose.${log[timestamp]}.log"
log[error]="/tmp/vdbench.benchmark.error.${log[timestamp]}.log"
log[results]="/tmp/vdbench.benchmark.${log[timestamp]}.log"
log[info]="/tmp/vdbench.benchmark.info.${log[timestamp]}.log"
log[logOutput]="vdbench.global.log"
vdbenchResultsLog[writetest]="write_test_"
vdbenchResultsLog[readtest]="read_test_"
vdbenchResultsLog[out]="out_"
storageInfo[json]="storageInfo.json"

storageInfo[remoteScriptsPath]="/home"
storageInfo[localScriptPath]="/usr/global/scripts/SVC"
storageInfo[mkVdisks]="mk_vdisks"
storageInfo[mkArray]="mk_arrays_master"

#### color sheame

printf "test time stemp %s\n" ${log[timestamp]}

wrap_color() {
	text="$1"
	shift
	color "$@"
	echo -n "$text"
	color reset
	echo
}

wrap_good() {
	echo "$(wrap_color "$1" white): $(wrap_color "$2" green)"
}
wrap_bad() {
	echo "$(wrap_color "$1" bold): $(wrap_color "$2" bold red)"
}
wrap_warning() {
	wrap_color >&2 "$*" red
}

parse_parameter() {

if [[ $# < 1 ]]; then
    usage
    exit
fi

while [[ $# > 1 ]]
do
    key="${1}"
    shift
    
    case "${key}" in

        --hsrm  )
            vdbench_params[hsrm]="$1"
            shift
            ;;
        --hrdev)
            vdbench_params[hrdev]="$1"
            shift
            ;;
        --cshost)
            vdbench_params[cshost]="$1"
            shift
            ;;
        --csdev)
            vdbench_params[csdev]="$1"
            shift
            ;;
        -vs | --volsize )
            #volsize="$1"
            storageInfo[volsize]="$1"
            shift
            ;;
        -vn | --volnum )
            storageInfo[volnum]="$1"
            shift
            ;;
        -s | --stand-name )
            storageInfo[stand_name]="$1"
            shift
            ;;
        -c | --clients)
            vdbench_params[clients]="$1"
            shift
            ;;
        -th | --threads )
            #thrades="$1"
            vdbench[threads]="$1"
            shift
            ;;
        -bs | --blocksize )
            #blocksize=( $1 )
            vdbench[blocksize]=$1
            shift
            ;;
        -i | --interval )
            #interval="$1"
            vdbench[interval]="$1"
            shift;;
        -rd | --readdata )
            #read_data="$1"
            vdbench[readdata]="$1"
            shift
            ;;
        -wd | --writedata )
            #write_data="$1"
            vdbench[write_data]="$1"
            shift
            ;;
        -d | --debug )
            log[debug]="true"
            #debug="true"
            shift
            ;;
        -v | --verbose )
            log[verbose]="true"
            #verbose="true"
            shift
            ;;
        -vu | --volsizeunit )
            #volsizeunit="$1"
            storageInfo[volsizeunit]="$1"
            shift
            ;;
        -t | --type )
            #type="$1"
            storageInfo[type]="$1"
            shift
            ;;
        -vt | --voltype )
            #voltype="$1"
            storageInfo[voltype]="$1"
            shift
            ;;
        -rt | --raidtype)
            storageInfo[raidtype]="$1"
            ;;
        -cr | --cmprun )
            vdbench[cmprun]="$1"
            ;;
        --cleanenv )
            vdbench_params[cleanenv]="true"
            ;;
        -vd | --vdbin )
            vdbench[vdbin]="$1"
            ;;
        --help )
            usage
            ;;
        #*)
        #    usage
	#		;;
    esac
done
}

usage(){
echo -e "\
\tUsage:

\t $(basename $0) [ -c | --stand-name <storage name> ] [ -t | --type <xiv|svc> ] [ -c | --clients <client list> ]  \r
\t[ -vs | --volsize <size> ] [ -vn | --volnum <vol number> ] [ -vu | --volsizeunit <GB|GiB> ] [ -vt | --voltype <cmp|fa> ] \r
\t[ -rd | --readdata <size> ] [ -wd | --writedata <size> ] [ -th | --threads <number> ] [ -bs | --blocksize <blocksize> ] \r
\t[ -cr | --cmprun <comp ratio> ] \r
\t[  -d | --debug ] [ -v | --verbose  ] 

 Storage Arguments :
   -s  | --stand-name  stand name   : <no defaults>
   -c  | --clients     clients test : <no defaults most>
   -t  | --type        storage type : <default svc>
   -vs | --volsize     volume size  : <default 488>
   -vn | --volnum      number of volume : <default 128>
   -vu | --volsizeunit size unit type : < t|g|m > <default g >
   -vt | --voltype     run type compression or fully allocation : <default cmp>
   -rd | --raidtype    raid type for volume creation : <default raid10>

 Vdbench Arguments :
   -vd | --vdbin       vdbench bin execution path
   -wd | --writedata   write data from storage : <default 3000g>
   -rd | --readdata    read data from storage : <default 1000g>
   -th | --threads     threads per lun : <default 4>
   -bs | --blocksize   test blocksize  : <default 4k,8k,16k,32k etc> full scale
   -cr | --cmprun      test compression ratio : <default 30,50,65 etc> full scale
   -i  | --interval    test results interval output display <defaul 10 sec>
 Vdbench extra options:
   --seekpct           
   --
 other parameters :
  --mail              send results by mail : <default RTC_SVC>
  --xlsx              create excel file : <default disable>
  --upload            upload json file to par if no errors found

 extra parameters :
  --hsrm              host storage remove   : <default : yes>
  --hrdev             rescan host device    : <default : yes>
  --cshost            create storage host   : <default : yes>
  --csdev             create storage host   : <default : yes>


 debug info :
  -b | --debug        default false
  -v | --verbose      default false 


Example: Creating 128 volums of 488 GB and attaching them 'wl9 wl10 wl11'\r

$(basename $0) -s rtc02t --volnum 128 --volsize 488  -c \"wl9 wl10 wl11\" -type svc"
}

checking_params()
{
if [[ ! {vdbench_params[vdbin]}  ]]; then
    printf "using default path to vdbench test"
    vdbench[vdbin]="/root/vdbench"
fi

if [[ ! ${storageInfo[stand_name]} ]];then
	printf "ERRROR : STORAGE NOT DEFINED!!!!!! \n "
	usage
	exit
fi
if [[ ! ${vdbench_params[clients]}  ]];then
	printf "ERRROR : CLIENTS NOT DEFINED!!!!!! \n "
	usage
	exit
fi

if [[ ! ${vdbench_params[hsrm]}  ]]; then
    vdbench[hsrm]="true"
fi

if [[ ! ${vdbench_params[hrdev]}  ]]; then
    vdbench[hrdev]="true"
fi

if [[ ! ${vdbench_params[cshost]}  ]]; then
    vdbench[cshost]="true"
fi

if [[ ! ${vdbench_params[csdev]}  ]]; then
    vdbench[csdev]="true"
fi

if [[ ! ${storageInfo[volsizeunit]} ]];then
	storageInfo[volsizeunit]="g"
fi
if [[ ! ${storageInfo[volnum]} ]];then
	storageInfo[volnum]="128"
fi
if [[ ! ${vdbench[threads]} ]] ; 
then
    vdbench["threads"]="4"
fi
if [[ ! ${vdbench[blocksize]} ]]; then
    vdbench[blocksize]=""1024k" "512k" "256k" "128k" "64k" "32k" "16k" "8k" "4k""
	#printf "setting default value to [ blocksize ] %s \n " "${vdbench_params[blocksize]}"
fi
if [[ ! ${storageInfo[volsize]} ]];then
	storageInfo[volsize]="488"
fi
if [[ ! ${storageInfo[vol_num]} ]];then
	storageInfo[vol_num]="128"
fi
if [[ ! ${vdbench[interval]} ]];then
	vdbench[interval]="10"
fi
if [[ ! ${vdbench[read_data]} ]];then
	vdbench[read_data]="1000g"
fi
if [[ ! ${vdbench[write_data]} ]];then
	vdbench[write_data]="3000g"
fi
if [[ ! ${vdbench[cmprun]} ]]; then
	vdbench[cmprun]=" "1.3" "1.7" "2.3" "3.5" "11" "
fi
if [[ ! ${log[debug]} ]];then
	log[debug]="false"
	printf "debug not defined %s\n" ${log[debug]}
fi
if [[ ! ${log[verbose]} ]];then
	log[verbose]="false"
	printf "verbose not defined %s\n" ${log[verbose]}
fi
if [[ ! ${storageInfo[voltype]} ]];then
#	storageInfo[voltype]="cmp"
	storageInfo[voltype]="COMPRESSED"
fi
if [[ ! ${storageInfo[raidType]} ]] ; then
	storageInfo[raidType]="raid5"
fi

if [[ ! $vdbench_params[cleanenv]} ]]; then
    vdbench_params[cleanenv]="true"
fi
}

print_params() 
{
printf "%10s | %1s\n" "vdbench key" "param value"
	for param  in "${!vdbench_params[@]}"
	do
		logger info  "$param:${vdbench_params[$param]}"
	done
}
function logger(){
	#echo "[`date '+%d/%m/%y %H:%M:%S:%2N'`]" $@
	type=$1
    ouput=$2
	if [[ $type == "debug" ]]; then
		if [[ ${log[debug]} == "true" ]] ; then printf "[%s] [%s  ] [%s] %s\n" "`date '+%d/%m/%y %H:%M:%S:%2N'`" "DEBUG" "${FUNCNAME[1]}" "$ouput" | tee -a ${log[debug]}; fi
	elif [[ $type == "info" ]] ; then
		printf "[%s] [%s   ] %s\n" "`date '+%d/%m/%y %H:%M:%S:%2N'`" "INFO" "$ouput" | tee -a ${log[info]}
	elif [[ $type == "warn" ]] ; then
		printf "[%s] [%s] %s\n" "`date '+%d/%m/%y %H:%M:%S:%2N'`" "WARNING" "$ouput" | tee -a ${log[info]}
	elif [[ $type == "error" ]] ; then
		printf "[%s] [%s  ] [%s] %s\n" "`date '+%d/%m/%y %H:%M:%S:%2N'`" "ERROR" "${FUNCNAME[1]}" "$ouput" | tee -a ${log[error]}
	elif [[ $type == "fetal" ]] ; then
		printf "[%s] [%s  ] [%s] %s\n" "`date '+%d/%m/%y %H:%M:%S:%2N'`" "FETAL" "${FUNCNAME[1]}" "$ouput" | tee -a ${log[error]} ; exit
	elif [[ $type == "ver" || $type == "verbose" ]] ; then
		if [[ ${log[verbose]} == "true" ]] ; then printf "[%s] [%s] [%s] %s\n" "`date '+%d/%m/%y %H:%M:%S:%2N'`" "VERBOSE" "${FUNCNAME[1]}" "$ouput" | tee -a ${log[verbose]} ;fi
	elif [[ ! $type =~ "debug|ver|error|info" ]] ; then
		printf "[%s] %s\n" "`date '+%d/%m/%y %H:%M:%S:%2N'`" "$type" 
	fi

}
function debug(){
    [ ${log[debug]} == "true"  ] && $@
    
}

function storageRemoveHosts() {
	logger "info" "Removing Existing hosts : "$(ssh -p 26 ${storageInfo[stand_name]} lshost -nohdr | awk '{print $2}' | tr "\n" "," | sed -e 's/,$//g')

    if [[ ${log[debug]} == "true" ]] ; then 
		logger "debug" "ssh -p 26 ${storageInfo[stand_name]} \"i=\"0\"; while [ 1 -lt \`lshost|wc -l\` ]; do echo -e \"host_id \$i \n \"; svctask rmhost -force \$i; i=\$[\$i+1]; done\" "
	else
		ssh -p 26 ${storageInfo[stand_name]} "i=\"0\"; while [ 1 -lt \`lshost|wc -l\` ]; do svctask rmhost -force \$i; i=\$[\$i+1]; done"
	fi
	sleep 2
}
function hostRescan(){
#storageInfo[vdiskPerClient]=$(( storageInfo[volnum] / storageInfo ))

	for c in ${vdbench_params[clients]}
	do
        logger "info" "$c host rescanning "
        ssh $c /usr/global/scripts/rescan_all.sh &> ${log[globalLog]}
        hostmPathCount=$( ssh $c "multipath -ll|grep -c mpath" )
        logger "info" "vdisk per client ${storageInfo[vdiskPerClient]} , vdisks found : [ \" $hostmPathCount \" ]"

		hostDeviceCount=$( ssh $c multipath -ll|grep -c mpath )
		if [[ ! ${storageInfo[vdiskPerClient]} == $hostDeviceCount ]] ; then 
			logger "fetal" "!!!!! ERROR | unbalanced devices on host $c | device count [ $hostDeviceCount ] | ERROR !!!!!" 
			exit
		fi
    done
}

function removeMdiskGroup(){
	mdiskid=`ssh -p 26 ${storageInfo[stand_name]} ""lsmdiskgrp |grep -v id | sed -r 's/^[^0-9]*([0-9]+).*$/\1/'""`
	countMdiskids=`ssh -p 26 ${storageInfo[stand_name]} "lsmdiskgrp -nohdr | wc -l "`
#    logger "info" "Removing mdiskgrp id : $mdiskid from ${storageInfo[stand_name]}" 
    if [[ $countMdiskids -ge "1" ]]; then
        if   [[ ${log[debug]} == "true" ]]; then
            logger "debug" "Removing mdiskgrp id : $mdiskid from ${storageInfo[stand_name]}" 
        elif [[ ${log[verbose]} == "true" ]]; then
            logger "info" "Removing mdiskgrp id : $mdiskid from ${storageInfo[stand_name]}" 
		    ssh -p 26 ${storageInfo[stand_name]} svctask rmmdiskgrp -force $mdiskid
        else 
            logger "info" "Removing mdiskgrp id : $mdiskid from ${storageInfo[stand_name]}" 
	        ssh -p 26 ${storageInfo[stand_name]} svctask rmmdiskgrp -force $mdiskid
        fi
    else
        logger "info" "No mdiskgrp exist on ${storageInfo[stand_name]}" 
    fi
}

function createHosts() {
clients=${vdbench_params[clients]}
storageInfo[hostCount]=0
logger "info" "Creating hosts ${clients[@]}"
directoryStracture[mountScripts]="scripts"
directoryStracture[pathScripts]="/usr/global/scripts/"

#totalFC=0
for c in ${vdbench_params[clients]}
do
	storageInfo[hostCount]=$(( storageInfo[hostCount] + 1 ))
    if [[ $(ssh $c "grep -qs "${directoryStracture[mountScripts]}" /proc/mounts ") == "0" ]] ; then
        logger "info" "[ ${directoryStracture[mountScripts]} ] is mounted"
        logger "ver" "command | grep -qs \"${directoryStracture[mountScripts]}\""
        wwpn=`ssh $c /usr/global/scripts/qla_show_wwpn.sh | grep Up | awk '{print $1}' | tr "\n" ":"| sed -e 's|\:$||g'`
        wwpnHostCount=`ssh $c /usr/global/scripts/qla_show_wwpn.sh | grep -c Up`
    else
        logger "ver" "command \"awk '{print \$2 }' /proc/mounts \| grep -qs \"\^${directoryStracture[mountScripts]}\$\"]"
        logger "info" "[ ${directoryStracture[mountScripts]} ] is not mounted"
        #wwpnHostCount=$(hostWWN $c)
        hostWWN $c
    fi
    logger "ver" " [$c] host wwpn ${hostInfo[[$c]['hostWWPN']]}" 
    logger "debug" "  COMMAND \"ssh -p 26 ${storageInfo[stand_name]} svctask mkhost -fcwwpn ${hostInfo[[$c]['hostWWPN']]} -force -iogrp io_grp0:io_grp1:io_grp2:io_grp3 -name $c -type generic 2>/dev/null\""
        #ssh -p 26 ${storageInfo[stand_name]} svctask mkhost -fcwwpn $wwpn  -force -iogrp io_grp0:io_grp1:io_grp2:io_grp3 -name $c -type generic 2>/dev/null
    #ssh ${storageInfo[stand_name]} -p 26 svctask mkhost -fcwwpn $wwpn  -force -iogrp io_grp0:io_grp1:io_grp2:io_grp3 -name $c -type generic &>/dev/null
    ssh ${storageInfo[stand_name]} -p 26 svctask mkhost -fcwwpn ${hostInfo[[$c]['hostWWPN']]}  -force -iogrp io_grp0:io_grp1:io_grp2:io_grp3 -name $c -type generic &>/dev/null
done
	logger "info" "Total Host Created ${storageInfo[hostCount]}"
    storageInfo[vdiskPerClient]=$(( storageInfo[volnum] / storageInfo[hostCount]  ))
    logger "verbose" "Total vdisk per client ${storageInfo[vdiskPerClient]}" 
}

function hostWWPNCount(){
    local host=$1

}
function hostWWN(){
    local host=$1
    logger "info" "[ $host ] Start collecting host wwpn from "
    hostInfo[fc_host_path]="/sys/class/fc_host/"
    hostInfo[scsi_host_path]="/sys/class/scsi_host/"

    hostInfo[[$host]['fc_hosts']]=$(ssh $host "find ${hostInfo[fc_host_path]} -maxdepth 1 -mindepth 1 -type l -exec basename {} \;"  )
    hostInfo[[$host]['fc_count']]=0
    hostInfo[[$host]['onlineWWNCount']]=0
    hostInfo[[$host]['offlineWWNCount']]=0
    #printf "fc host %s\n" "$(echo  ${hostInfo[[$host]['fc_hosts']]} | tr -d '\n' ) "
    for fc_host in  $( echo ${hostInfo[[$host]['fc_hosts']]}|tr -d '\n' ); do
        logger "debug" "ssh $host "cat ${hostInfo[fc_host_path]}/$fc_host/port_name ${hostInfo[fc_host_path]}/$fc_host/port_state ${hostInfo[scsi_host_path]}/$fc_host/link_state| tr '\n' ';'""
        hostInfo[[$host][$fc_host]]=`ssh $host "cat ${hostInfo[fc_host_path]}/$fc_host/port_name ${hostInfo[fc_host_path]}/$fc_host/port_state ${hostInfo[scsi_host_path]}/$fc_host/link_state| tr '\n' ';'"`
     #echo "host $host fc_host ${hostInfo[[$host][$fc_host]]} fc_count = ${hostInfo[[$host]['fc_count']]}"

     if [[ $( echo ${hostInfo[[$host][$fc_host]]} | grep -i up ) ]] ; then
         hostInfo[[$host]['fc_count']]=$(( hostInfo[[$host]['fc_count']]+1 ))
         hostInfo[[$host]['onlineWWNCount']]=$(( hostInfo[[$host]['onlineWWNCount']]+1 ))
         if [[ ${hostInfo[[$host]['hostWWPN']]} == "" ]] ; then
             hostInfo[[$host]['hostWWPN']]=$(echo ${hostInfo[[$host][$fc_host]]}|awk -F';' '{print $1}' | sed -e 's/^0x//g' )
             logger "ver" "WWPN online ${hostInfo[[$host]['hostWWPN']]}"
         else
             hostInfo[[$host]['hostWWPN']]="${hostInfo[[$host]['hostWWPN']]}:"$(echo ${hostInfo[[$host][$fc_host]]}|awk -F';' '{print $1}' | sed -e 's/^0x//g' )
              #printf "WWPN online %s\n" "${hostInfo[[$host]['hostWWPN']]}"
             logger "ver" "WWPN online ${hostInfo[[$host]['hostWWPN']]}"
         fi
     elif [[ $( echo ${hostInfo[[$host][$fc_host]]} | grep -i Down ) ]] ; then
         hostInfo[[$host]['offlineWWNCount']]=$(( hostInfo[[$host]['offlineWWNCount']]+1 ))
         hostInfo[[$host]['fc_count']]=$(( hostInfo[[$host]['fc_count']]+1 ))
         if [[ ${hostInfo[[$host]['hostWWPNoffline']]} == "" ]] ; then
             hostInfo[[$host]['hostWWPNoffline']]=$(echo ${hostInfo[[$host][$fc_host]]}|awk -F';' '{print $1}' | sed -e 's/^0x//g' )
             logger "ver" "WWPN offline %s ${hostInfo[[$host]['hostWWPNoffline']]}"
         else
             hostInfo[[$host]['hostWWPNoffline']]="${hostInfo[[$host]['hostWWPNoffline']]}:"$(echo ${hostInfo[[$host][$fc_host]]}|awk -F';' '{print $1}' | sed -e 's/^0x//g' )
         fi
     fi

    done
    if [[ ${hostInfo[[$host]['hostWWPN']]} != "" ]] ; then logger "info" "WWPN online ${hostInfo[[$host]['hostWWPN']]}" ; fi
    if [[ ${hostInfo[[$host]['hostWWPNoffline']]} != "" ]] ; then logger "warn" "WWPN offline ${hostInfo[[$host]['hostWWPNoffline']]}" ; fi
    
    if (( ${hostInfo[[$host]['onlineWWNCount']]} % 2 != "0" ))  ; then
        logger "error" "$host has only ${hostInfo[[$host]['onlineWWNCount']]} fc ports online "
        exit
    fi
}


function clearStorageLogs() {
	logger "info" "Cleaning Storage logs"
	ssh -p 26 ${storageInfo[stand_name]} svctask clearerrlog -force
}
function initLogger(){
logger "test"

}
function getStorageInfo(){
	logger "info" "${storageInfo[stand_name]} Collecting Storage Information"
	storageInfo[svcVersion]=$( ssh -p 26 ${storageInfo[stand_name]} cat /compass/version )
	logger "debug" "svc|version|command|\"ssh -p 26 ${storageInfo[stand_name]} cat /compass/version\" "
	logger "ver" "[svc|version|${storageInfo[svcVersion]}]" 

	storageInfo[svcBuild]=$( ssh -p 26 ${storageInfo[stand_name]} cat /compass/vrmf )
	logger "debug" "[svc|build|command|\"ssh -p 26 ${storageInfo[stand_name]} cat /compass/vrmf\""
	logger "ver" "[svc|build|${storageInfo[svcBuild]}]"

	storageInfo[hardware]=$( ssh -p 26 ${storageInfo[stand_name]} sainfo lshardware | grep hardware | awk '{print $2}' )
	logger "debug" "svc hardware|command|\"ssh -p 26 ${storageInfo[stand_name]} sainfo lshardware | grep hardware | awk '{print \$2}'\"" 
	logger "ver" "[svc|hardware|${storageInfo[hardware]}]"

	if [[ $( ssh -p 26 ${storageInfo[stand_name]} lscontroller -nohdr | awk '{print $1}') == "" ]]; then
		storageInfo[backend]="none"
		logger "debug" "svc|backend|output|${storageInfo[backend]}"
		logger "debug" "svc|driveCount|command|\"ssh -p 26 ${storageInfo[stand_name]} lsdrive -nohdr | wc -l\""
		storageInfo[driveCount]=$( ssh -p 26 ${storageInfo[stand_name]} lsdrive -nohdr | wc -l )
		logger "ver" "[svc|driveCount|${storageInfo[driveCount]}]"
	else
		logger "debug" "svc|backend|command|\"ssh -p 26 ${storageInfo[stand_name]} sainfo lscontroller -nohdr| awk '{print \$1}'\"" 
		storageInfo[backend]=$( ssh stcon "/opt/FCCon/fcconnect.pl -op showconn -stor ${storageInfo[stand_name]} | grep Storage | awk '{print \$3}'" 2>/dev/null  )
		logger "ver" "[svc|backend|${storageInfo[backend]}]"
	fi

}

function getStorageVolumes(){
		logger "debug" "svc|mdiskCount|command|\"ssh -p 26 ${storageInfo[stand_name]} lsmdisk -nohdr | wc -l\""
		storageInfo[mdiskCount]=$( ssh -p 26 ${storageInfo[stand_name]} lsmdisk -nohdr | wc -l )
		logger "ver" "svc|mdiskCount|output|${storageInfo[mdiskCount]}"

		logger "debug" "svc|mdiskSize|command|\"ssh -p 26 ${storageInfo[stand_name]} lsmdisk -nohdr | awk '{ print $7 }' | uniq | tr '\n' ' '\""
		storageInfo[mdiskSize]=$( ssh -p 26 ${storageInfo[stand_name]} lsmdisk -nohdr | awk '{ print $7 }' | uniq | tr '\n' ' ' )
		logger "ver" "svc|mdiskSize|output|${storageInfo[mdiskSize]}"
}

function vdbenchDirectoryResutls() {
	results_path="vdbench_benchmark_test"

	log[resultsPath]="${directoryStracture[absPath]}/${storageInfo[svcBuild]}/${storageInfo[svcVersion]}/${log[timestamp]}/$bs"
	logger "ver" "results path        : [ ${log[resultsPath]} ]"
	createDirectory ${log[resultsPath]}

	log[test_results]="${log[resultsPath]}/test_results"
	logger "ver" "test results path   : [ ${log[test_results]} ]"
    createDirectory ${log[test_results]}

	log[test_files]="${log[resultsPath]}/test_files"
	logger "ver" "test files path     : [ ${log[test_files]} ]"
    createDirectory ${log[test_files]}

	log[test_data]="${log[resultsPath]}/output_data"
	logger "ver" "test data path      : [ ${log[test_data]} ]"
    createDirectory ${log[test_data]}
}

function vdbenchMainDirectoryCreation(){

	directoryStracture[absPath]="benchmark_results"
	logger "ver" "absulte path        : [ ${directoryStracture[absPath]} ]"
	createDirectory ${directoryStracture[absPath]}

	log[logPath]="${directoryStracture[absPath]}/${storageInfo[svcBuild]}/${storageInfo[svcVersion]}/${log[timestamp]}"
	logger "ver" "results path        : [ ${log[logPath]} ]"
	createDirectory ${log[logPath]}

	log[globalLog]="${log[logPath]}/${log[logOutput]}"
	logger "ver" "globalLog file        : [ ${log[globalLog]} ]"
}

function createDirectory() {
	directoryPath=$1
	if [ ! -d $directoryPath ] ; then
		logger "ver" "creating directory [ $directoryPath ]"
		mkdir -p $directoryPath
	fi

}
function vdbenchResultsFiles() {

	log[output_file]=${log[test_results]}/"out_$CP"
	logger "ver" "test output file        : [ ${log[output_file]} ]"
#	log[disk_file]=$CP"_disk_list"
	
	vdbench[write_test]=${log[test_files]}/$CP"_write"
	logger "ver" "vdbench write test file : [ ${vdbench[write_test]} ]"

	vdbench[read_test]=${log[test_files]}/$CP"_read"
	logger "ver" "vdbench read test file  : [ ${vdbench[read_test]} ]"
	#log[disk_list]=${log[test_files]}/$disk_file

	vdbench[disk_list]=${log[test_files]}/$CP"_disk_list"
	logger "ver" "vdbench disk list file  : [ ${vdbench[disk_list]} ]"

	log[test_info]=${log[resultsPath]}"/vdbench_benchmark_information_$CP.log"
	logger "ver" "test info file          : [ ${log[test_info]} ]"
}

function createStorageVolumes(){

#ssh $1 -p 26 ls /home/mk_arrays_master >/dev/null
removeMdiskGroup

storageInfo[mkMasterArray]="${storageInfo[remoteScriptsPath]}/${storageInfo[mkArray]} fc ${storageInfo[raidType]} sas_hdd "
storageInfo[mkVdisk]="${storageInfo[remoteScriptsPath]}/${storageInfo[mkVdisks]} fc 1 ${storageInfo[volnum]} "
logger "info" "Running with storage hardware  ${storageInfo[hardware]}"

storageInfo[mkVdiskPattern]="^T5H|SV1|DH8$"
storageInfo[mkArrayPattern]="^[456]00$"


if [[ ${storageInfo[hardware]} =~ ${storageInfo[mkArrayPattern]} ]]; then
    logger "info" "storage based drives ${storageInfo[hardware]} "
	storageInfo[arrayGroup]=8
    storageInfo[driveCount]=$(ssh -p 26 ${storageInfo[stand_name]} lsdrive -nohdr | wc -l)
    storageInfo[numberMdiskGroup]=$(( ${storageInfo[driveCount]} / ${storageInfo[arrayGroup]} ))
	storageInfo[mkMasterArray]+="${storageInfo[driveCount]} ${storageInfo[arrayGroup]} ${storageInfo[numberMdiskGroup]} "
	storageInfo[mkMasterArray]+="${storageInfo[volnum]} ${storageInfo[volsize]} ${storageInfo[voltype]} NOFMT NOSCRUB"
    storageCopyMK

    if [[ ${log[debug]} =~ "true" ]]; then
        logger "debug" "ssh -p 26 ${storageInfo[stand_name]} ${storageInfo[mkMasterArray]}"
    elif [[ ${log[verbose]} == "true" ]]; then
    	logger "ver" "command| ssh -p 26 ${storageInfo[stand_name]} ${storageInfo[mkMasterArray]}"
        ssh -p 26 ${storageInfo[stand_name]} ${storageInfo[mkMasterArray]} &> ${log[globalLog]}
    else
        logger "info" "Creating volumes on ${storageInfo[stand_name]}"
        logger "info" "mkArray=[${storageInfo[mkMasterArray]}]"
        ssh -p 26 ${storageInfo[stand_name]} ${storageInfo[mkMasterArray]} &> ${log[globalLog]}
    fi

elif [[ ${storageInfo[hardware]} =~ ${storageInfo[mkVdiskPattern]} ]] ; then
    logger "info" "storage based mdisks  ${storageInfo[hardware]} "
    storageCopyMK
    storageInfo[mkVdisk]=${storageInfo[mkVdisk]}" $(( ${storageInfo[volsize]} * 1000 ))"
    storageInfo[mkVdisk]=${storageInfo[mkVdisk]}" 0 NOFMT COMPRESSED AUTOEXP"

#   printf "mkVdisk=[%s]" "${storageInfo[mkVdisk]}"
    if [[ ${log[debug]} =~ "true" ]]; then
        logger "debug" "ssh -p 26 ${storageInfo[stand_name]} ${storageInfo[mkVdisk]}"
    elif [[ ${log[verbose]} == "true" ]]; then
    	logger "ver" "command| ssh -p 26 ${storageInfo[stand_name]} ${storageInfo[mkMasterArray]}"
        ssh -p 26 ${storageInfo[stand_name]} ${storageInfo[mkVdisk]} &> ${log[globalLog]}
    else
        logger "info" "Creating volumes on ${storageInfo[stand_name]}"
        logger "info" "mkVdisk=${storageInfo[mkVdisk]}"
       	#ssh ${storageInfo[stand_name]} -p 26 ${storageInfo[mkVdisk]} fc 1 ${storageInfo[volnum]} 495600 0 NOFMT COMPRESSED AUTOEXP &> ${log[globalLog]}
       	ssh ${storageInfo[stand_name]} -p 26 ${storageInfo[mkVdisk]} &> ${log[globalLog]}
    fi
	#	logger "error" "${storageInfo[mkVdisks]} does not exist on ${storageInfo[stand_name]} path ${storageInfo[remoteScriptsPath]}/${storageInfo[mkVdisks]}"
else
    logger "info" "Unknown Hardware Type [ ${storageInfo[hardware]} ]"
    exit
fi

sleep 10
}
function storageCopyMK(){
#        if ($1 == "hardware") {
#                if ($2 ~ /^[48C][AFG][248]$/)   type="SVC"      ### Matches 4F2 8F2 8F4 8G4 8A4 CF8 CG8
#                if ($2 == "DH8")                type="BFN"      ### mkVdisks
#                if ($2 ~ /[13]00/ )             type="V7000"    ### mkArray
#                if ($2 ~ /[45]00/ )             type="FAB1"     ### 400 is 6-core FAB
#                if ($2 ~ /T5H/ )                type="TB5"      ### mkVdisks
#                if ($2 ~ /SV1/ )                type="CAYMAN"   ### mkVdisks
#                if ($2 ~ /500/ )                type="FAB1"     ### mkArray
#                if ($2 ~ /600/ )                type="FAB2"     ### mkArray
#                if ($2 ~ /S01/ )                type="Lenovo"
   # /^[T5H][SV1][S01][13][456]00$/ mkVdisk
   # /^[13]00[456]00$/ mkArray
    #if   [[ ${storageInfo[hardware]} =~ /^[48C][AFG][248][SV1]$/ ]]; then
    
    #if [[ ${storageInfo[hardware]} =~ ^[13456]00|[SV1]|[T5H]|[S01]$ ]]; then
    if [[ ${storageInfo[hardware]} =~ ${storageInfo[mkVdiskPattern]} ]]; then
        logger "info" "Checking if ${storageInfo[mkVdisk]} exist"
        if [[ $(ssh ${storageInfo[stand_name]} "[ -e ${storageInfo[remoteScriptsPath]}/${storageInfo[mkVdisks]} ]") -ne "0" ]]; then
		    logger "warn" "${storageInfo[mkVdisks]} does not exist on ${storageInfo[stand_name]} path ${storageInfo[remoteScriptsPath]}/${storageInfo[mkVdisks]}"
            scp -P 26 ${storageInfo[localScriptPath]}/${storageInfo[mkVdisks]} ${storageInfo[stand_name]}:${storageInfo[remoteScriptsPath]}
            logger "ver" "changing permission to ${storageInfo[mkVdisks]}"
            ssh ${storageInfo[stand_name]} "chmod a+x ${storageInfo[remoteScriptsPath]}/${storageInfo[mkVdisks]}"
        fi
    elif [[ ${storageInfo[hardware]} =~ ${storageInfo[mkArrayPattern]} ]];then
	    if [[ $(ssh ${storageInfo[stand_name]} "[ -e ${storageInfo[remoteScriptsPath]}/${storageInfo[mkArray]} ]") -ne "0" ]]; then
            logger "warn" "copying files to ${storageInfo[stand_name]} ${storageInfo[mkArray]}"
            scp -P 26 ${storageInfo[localScriptPath]}/${storageInfo[mkArray]} ${storageInfo[stand_name]}:${storageInfo[remoteScriptsPath]}
            logger "ver" "changing permission to ${storageInfo[mkArray]}"
            ssh ${storageInfo[stand_name]} "chmod a+x ${storageInfo[remoteScriptsPath]}/${storageInfo[mkArray]}"
        fi
    else
        logger "info" "Error unknow system hardware"
        exit
    fi
    
}

function getHostLunSize(){
    host=$1
    storageInfo[lunSize]=$(ssh $host "multipath -ll| grep size | uniq | awk '{print \$1 }'| cut -f 2 -d '='")
    storageInfo[hostLunSize]=`echo ${storageInfo[lunSize]} | sed -e 's/.$//g'`
    let "storageInfo[hostLunSize] = ${storageInfo[hostLunSize]} - 1 "
    logger "debug" "host name $host Volume Acutal size is ${storageInfo[lunSize]} minus ${storageInfo[hostLunSize]}" 

}

function vdbenchDeviceList() {
echo " " > ${vdbench[disk_list]}

for client in ${vdbench_params[clients]}; do
count=1
    getHostLunSize $client
    for dev in `ssh $client multipath -l|grep "2145" | awk '{print \$1}'`; do
    	device="/dev/mapper/$dev"
    	if [[ ${log[debug]} == "true" ]]; then
            logger "debug" "vdbench sd output: sd=$client.$count,hd=$client,lun=$device,openflags=o_direct,size=${storageInfo[hostLunSize]}g,threads=${vdbench[threads]}"
            count=$(( count+1  ))
    	elif [[ ${log[verbose]} == "true" ]]; then
            logger "ver" "vdbench sd output: sd=$client.$count,hd=$client,lun=$device,openflags=o_direct,size=${storageInfo[hostLunSize]}g,threads=${vdbench[threads]}"
            echo  "sd=$client.$count,hd=$client,lun=$device,openflags=o_direct,size=${storageInfo[volsize]}g,threads=${vdbench[threads]}" >> ${vdbench[disk_list]}
            count=$(( count+1  ))
        else
            echo  "sd=$client.$count,hd=$client,lun=$device,openflags=o_direct,size=${storageInfo[hostLunSize]}g,threads=${vdbench[threads]}" >> ${vdbench[disk_list]}
            count=$(( count+1  ))
        fi
    done
done
}

function vdbenchWriteTest(){
echo "
compratio=$CP
messagescan=no

" > ${vdbench[write_test]}

for client in ${vdbench_params[clients]}; do
	if [[ ${log[debug]} == "true" ]]; then
    	logger "debug" "hd=$client,system=$client.eng.rtca,shell=ssh,vdbench=/root/vdbench,user=root" >> ${vdbench[write_test]}
	elif [[ ${log[verbose]} == "true" ]]; then
    	logger "debug" "hd=$client,system=$client.eng.rtca,shell=ssh,vdbench=/root/vdbench,user=root" >> ${vdbench[write_test]}
    	echo "hd=$client,system=$client.eng.rtca,shell=ssh,vdbench=/root/vdbench,user=root" >> ${vdbench[write_test]}
	else
    	echo "hd=$client,system=$client.eng.rtca,shell=ssh,vdbench=/root/vdbench,user=root" >> ${vdbench[write_test]}
	fi
done
echo "
include=${vdbench[disk_list]}

wd=wd1,sd=*,xfersize=$bs,rdpct=0,rhpct=0,seekpct=0
rd=run1,wd=wd1,iorate=max,elapsed=24h,maxdata=${vdbench[write_data]},warmup=360,interval=${vdbench[interval]}
" >> ${vdbench[write_test]}
    if [[ ${log[debug]} == 'true' ]]; then
        logger "debug" "log output file ${log[output_file]}"
        logger "debug" "${vdbench[vdbin]}/vdbench -c -f ${vdbench[write_test]} -o ${log[test_data]}/output_$CP | tee -a ${log[output_file]}"
	elif [[ ${log[verbose]} == "true" ]]; then
        logger "ver" "${vdbench[vdbin]}/vdbench -c -f ${vdbench[write_test]} -o ${log[test_data]}/output_$CP | tee -a ${log[output_file]}"
        `${vdbench[vdbin]}/vdbench -c -f ${vdbench[write_test]} -o ${log[test_data]}/output_$CP | tee -a ${log[output_file]}`
    else
        `${vdbench[vdbin]}/vdbench -c -f ${vdbench[write_test]} -o ${log[test_data]}/output_$CP >> ${log[output_file]}`
    fi
}

function vdbenchReadTest(){
echo "
compratio=$CP
messagescan=no
" > ${vdbench[read_test]}

for client in ${vdbench_params[clients]}; do
	if [[ ${log[debug]} == "true" ]];then
    	logger "debug" " "hd=$client,system=$client.eng.rtca,shell=ssh,vdbench=/root/vdbench,user=root" >> ${vdbench[read_test]}"
	elif [[ ${log[verbose]} == "true" ]]; then
	    logger "ver" " "hd=$client,system=$client.eng.rtca,shell=ssh,vdbench=/root/vdbench,user=root" >> ${vdbench[read_test]}"
	    echo "hd=$client,system=$client.eng.rtca,shell=ssh,vdbench=/root/vdbench,user=root" >> ${vdbench[read_test]}
	else
    	echo "hd=$client,system=$client.eng.rtca,shell=ssh,vdbench=/root/vdbench,user=root" >> ${vdbench[read_test]}
	fi
done

echo "
include=${vdbench[disk_list]}

wd=wd1,sd=*,xfersize=$bs,rdpct=100,rhpct=0,seekpct=0
rd=run1,wd=wd1,iorate=max,elapsed=24h,maxdata=${vdbench[read_data]},warmup=360,interval=${vdbench[interval]}
" >> ${vdbench[read_test]}

    if [[ ${log[debug]} == 'true' ]];then
        logger "debug" "log output file ${log[output_file]}"
        logger "debug" "${vdbench[vdbin]}/vdbench -c -f ${vdbench[read_test]} -o ${log[test_data]}/output_$CP | tee -a ${log[output_file]}"

	elif [[ ${log[verbose]} == "true" ]]; then
        logger "ver" "${vdbench[vdbin]}/vdbench -c -f ${vdbench[read_test]} -o ${log[test_data]}/output_$CP | tee -a ${log[output_file]}"
        `${vdbench[vdbin]}/vdbench -c -f ${vdbench[read_test]} -o ${log[test_data]}/output_$CP | tee -a ${log[output_file]}`
    else
        `${vdbench[vdbin]}/vdbench -c -f ${vdbench[read_test]} -o ${log[test_data]}/output_$CP >> ${log[output_file]}`
    fi
}

function clear_storage_logs(){
    logger "ver" "Clearing Storage event logs"
    ssh ${storageInfo[stand_name]} "svctask clearerrlog -force"
}

function displayVdbenchResults() {
    declare -A testResultsData

    testResultsData[write]=`cat ${log[output_file]} | grep -i avg | head -1 | tr -s ' ' ',' | sed -e 's/$/\n/'`
    testResultsData[read]=`cat ${log[output_file]} | grep -i avg | tail -1 | tr -s ' ' ',' | sed -e 's/$/\n/'`
    logger "info" "vdbench result \t write results [ $(echo ${testResultsData[write]} | awk '{print $3}' ) ] read results $(echo ${testResultsData[read]} | awk '{print $4 }' ) }  "

}

#function _info(){ echo }
#function _error(){ echo }
#function _verbose(){ echo }
#function _debug(){ echo }
###
# function jsonFile
# function storageInfo
# function storageInfo
# function createTestFile
# function storageInfo

parse_parameter "$@"
checking_params 
if [[ ${log[debug]} == "true" ]]  ; then print_params ; fi
getStorageInfo
vdbenchMainDirectoryCreation
if [[ ${vdbench[cshost]} == "true" ]] ; then 
    storageRemoveHosts
    createHosts
fi

for bs in ${vdbench[blocksize]}; do
	log[testCount]=1
	for CP in ${vdbench[cmprun]} ; do
        clearStorageLogs
	    if [[ ${vdbench[csdev]} == "true" ]] ; then createStorageVolumes ; fi
	    
        logger "info" "===[ ${log[testCount]} ]===[ blocksize | $bs ]====[ RATIO | $CP ]=============================================="
        getStorageVolumes
	    vdbenchDirectoryResutls
	    if [[ ${vdbench[hrdev]} == "true" ]] ; then hostRescan ; fi
		vdbenchResultsFiles
		vdbenchDeviceList
		vdbenchWriteTest
		vdbenchReadTest
        displayVdbenchResults
		log[testCount]=$(( log[testCount] + 1 ))
	done
    vdbench[hsrm]="true"
    vdbench[hrdev]="true"
    vdbench[cshost]="true"
    vdbench[csdev]="true"
done
# log output example
# [21/10/16 19:10:22] [INFO] 
# [21/10/16 19:10:22] [ERROR] 
# [21/10/16 19:10:22] [VERBOSE]  
# [21/10/16 19:10:22] [DEBUG] 
