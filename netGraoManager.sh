#!/bin/bash

# Copyleft (c) 2016
# author: Solicom Team
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. Neither the name of the Institute nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE INSTITUTE AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE INSTITUTE OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

##############################################################################
# A very simple application programs called signalBasedManager
# that stands for connect to the best AP
# usage: usage: $0 [-h] [-t interval] [-i interfaz] [-s SSIDPart] [-l signalLevel] [-v]"
# ???
#
##############################################################################




#If there are previous dhclient running, kill them
killall dhclient




## Look if the found AP (tapbss=$1 tapfreq=$2 tapssid=$3 tapsignal=$4) is better than the current best AP (
tratarap()
{
    local OPTIND opt cadena

    cadena="guifi"

    while getopts ":s:" opt; do
      case $opt in
        s)
          # echo "-H was triggered!" >&2
          cadena="${OPTARG}"
          ;;
      esac
    done

    # Clear all options and reset the command line
    shift $(( OPTIND -1 ))

    cadlen=${#cadena}

    local apssid 
    
    local tapbss=$1
    local tapfreq=$2
    local tapssid=$3
    local tapsignal=$4
    
    isGoodAp=`echo $tapssid | grep $cadena | wc -l`

    if [[ "$isGoodAp" = "1" ]]; then
      if [[ "$VERBOSE" > "1" ]]; then 
        echo "Looking AP:"
        echo $3
        echo $4
        echo $1
        echo $2
      fi
      if [[ "$tapsignal" -gt "$bestAPSignal" ]]; then
        bestAPSSID=$tapssid
        bestAPMAC=$tapbss
        bestAPSignal=$tapsignal
        bestAPFreq=$tapfreq
      fi
    fi
} 

INTERFACE=wlan0
VERBOSE=0
INTERVAL=1
bestAPSSID=""
bestAPMAC=""
bestAPSignal=-100
bestAPFreq=-1
SSIDPart=guifi
signalLevel=-80
signalMargin=10

usage()
{
echo "usage: $0 [-h] [-t interval] [-i interfaz] [-s SSIDPart] [-l signalLevel] [-v]"
echo "
  -h              this help
  -t interval     time in seconds between tests (1 default value)
  -i interfaz     interfaz to use (wlan0 default value)
  -s SSIDPart     part of the SSID to look for (guifi default value)
  -l signalLevel  minimum signal level in db to associate to an AP (-80 default value)
  -m signalMargin margin respect signalLevel in db to disconnect from an AP (10 default value)
  -v              be verbose
  -vv             be more verbose
  
example:

  ./netGraoManager.sh -vv -s UJInuvol -t 1 -l -82 -i wlan0
"
exit
}
 

while getopts ":ht:i:vs:l:m:" opt; do
  case $opt in
    t)
      # echo "-H was triggered!" >&2
      INTERVAL=$OPTARG
      ;;
    h)
      # echo "-h was triggered!" >&2
      usage
      ;;

    i)
      INTERFAZ=$OPTARG
      ;;

    s)
      SSIDPart=$OPTARG
      ;;

    l)
      signalLevel=$OPTARG
      ;;

    m)
      signalMargin=$OPTARG
      ;;

    v)
      VERBOSE=$(($VERBOSE+1))
      ;;

    \?)
      echo "Invalid option: -$OPTARG" >&2
      usage
      ;;
  esac
done

# Clear all options and reset the command line
shift $(( OPTIND -1 ))

# First parameter
#if [ -z "$1" ]; then
#    usage
#    exit
#fi

if [[ "$VERBOSE" > "2" ]]; then echo `date "+%d/%m/%Y-%H:%M:%S"` "step 1"; fi

#FIXME  Stop all interfaces except the one to be used
ip link set eth1 down

if [[ "$VERBOSE" > "2" ]]; then echo `date "+%d/%m/%Y-%H:%M:%S"` "step 2"; fi


#It seems that in some interfaces, you can get the following error
#RTNETLINK answers: Operation not possible due to RF-kill
#it is solve with 
rfkill unblock wifi   #FIXME #is rfkill present in openwrt??

if [[ "$VERBOSE" > "2" ]]; then echo `date "+%d/%m/%Y-%H:%M:%S"` "step 3"; fi


#Set up the network interface
ip link set $INTERFACE up

if [[ "$VERBOSE" > "2" ]]; then echo `date "+%d/%m/%Y-%H:%M:%S"` "step 4"; fi


# Disconnect the interfaz
iw dev $INTERFACE disconnect
#FIXME: If there is no connection this command returns: "command failed: Invalid argument (-22)"

if [[ "$VERBOSE" > "2" ]]; then echo `date "+%d/%m/%Y-%H:%M:%S"` "step 5"; fi


while :; do

if [[ "$VERBOSE" > "2" ]]; then echo `date "+%d/%m/%Y-%H:%M:%S"` "step 6"; fi


    assocAP=1
    # is it associated?
    assoc=`iw dev $INTERFACE link`
    currentAPSSID=`echo  "$assoc" | grep SSID`
    currentAPSignal=`echo  "$assoc" | grep signal`
    currentAPSignalValue=`echo $currentAPSignal | awk '{print $2}'`

    # is it connected to an AP?
    if [[ "`echo $assoc | grep 'Not connected' | wc -l`" = "1" ]]; then 
      assocAP=0
      if [[ "$VERBOSE" > "0" ]]; then echo `date "+%d/%m/%Y-%H:%M:%S"` "There is no associated AP"; fi
    else

      # To disconnect from an AP we allow a margin of signalMargin db from the signalLevel
      # The connection will depen on the ping FIXME ??? Esto no es así ???
      #FIXME: el margen debería ser una opción también
      #FIXME: Quitar esta opción y que sea el ping el que decida si se desconecta o no (o ponerlo como opción)
      if [[ "$currentAPSignalValue" -lt "$(($signalLevel-$signalMargin))" ]]; then
        assocAP=0
        if [[ "$VERBOSE" > "0" ]]; then 
          echo `date "+%d/%m/%Y-%H:%M:%S"` "The current AP has a bad signal: $currentAPSSID $currentAPSignal. Disconnecting ... "
        fi
      else
        if [[ "$VERBOSE" > "0" ]]; then echo `date "+%d/%m/%Y-%H:%M:%S"` "Associated to AP $currentAPSSID $currentAPSignal"; fi
      fi
    fi
    #if there is no a connection with the gateway
    #is there a ping with the gateway?
    if [[ "$assocAP" = "1" ]]; then
      noroute=`ip r | wc -l`
      if [[ "$noroute" = "0" ]]; then
        gatewayPing=0;
      else
        gateway=`ip r | grep default  | awk '{print $3}'`
     
        #FIXME User root can do ping with minimal interval lower tha 0.2 seconds, normal user can not
        #pping=`ping -c5 -i 0.2 -n -W 1 $gateway 2>/dev/null`
        pping=`ping -c5 -i 0.05 -n -W 1 $gateway 2>/dev/null`
        
        #if ping has failed, because there is no connection for example
        if [[ "$pping" = ""  ]]; then 
          gatewayPing="0";
        else
          gatewayPing=`echo $pping | grep 'transmitted,'| grep ", 100% packet loss" | wc -l`
          gatewayPing=$((1-$gatewayPing))
        fi
      fi

      if [[ "$gatewayPing" = "0" ]]; then 
        if [[ "$VERBOSE" > "0" ]]; then echo `date "+%d/%m/%Y-%H:%M:%S"` "There is an associated AP ($currentAPSSID), but there is no ping"; fi
      fi

    fi

    # Look for another AP
    if [[ "$assocAP" = "0" || "$gatewayPing" = "0" ]]; then
        nap=0
        
        bestAPSSID=""
        bestAPMAC=""
        bestAPSignal=-100
        bestAPFreq=-1
       
        lines=`iw dev $INTERFACE scan`

        while read lineorig; do
          line=`echo "$lineorig" | xargs`

          if [[ "${line:0:3}" = "BSS" ]] && [[ "${line:0:8}" != "BSS Load" ]]; then
            if [[ "$VERBOSE" > "1" ]]; then echo "Found AP $line"; fi 
            if [[ "$nap" == "0" ]]; then
              nap=1
            else
              # tratarap -s guifi "$apbss" "$apfreq" "$apssid" "$apsignal"
              tratarap -s $SSIDPart "$apbss" "$apfreq" "$apssid" "$apsignal"
            fi
            apbss="${line:4:17}"
          else
            if [[ "${line:0:3}" = "fre" ]]; then
              apfreq=${line:6}
            else 
              if [[ "${line:0:3}" = "SSI" ]]; then
                apssid=${line:6}
              else
                if [[ "${line:0:3}" = "sig" ]]; then
                  apsignal=${line:8:3}   # We supose all signals has two digits plus the minus sign !!!!!! FIXME
                fi
              fi
            fi
          fi
        done <<EOT
    $(echo "$lines")
EOT
        #Tratamos el último AP encontrado
        if [[ "$nap" != "0" ]]; then
              # tratarap -s guifi "$apbss" "$apfreq" "$apssid" "$apsignal"
              tratarap -s $SSIDPart "$apbss" "$apfreq" "$apssid" "$apsignal"
        fi
        
        if [[ "$VERBOSE" > "1" ]]; then 
          if [[ "$bestAPSSID" != "" ]]; then
            echo `date "+%d/%m/%Y-%H:%M:%S"` "The best AP found is: $bestAPSSID, $bestAPMAC, $bestAPSignal, $bestAPFreq"
          else
            echo `date "+%d/%m/%Y-%H:%M:%S"` "There are no APs found"
          fi
        fi
        
        #Si no ha encontrado ninguno, no se conecta.
        if [[ "$bestAPSSID" != "" ]]; then

          # Do not connect if the signal is worst than the $signalLevel
          if [[ "$bestAPSignal" -gt "$signalLevel" ]]; then
            # Connect to the AP and ask for an IP.

            #FIXME If it is already connected, it has not to try to reconnect ?????
            iw dev $INTERFACE disconnect
            #FIXME if there are spaces, it does not function ????
            iw dev $INTERFACE connect -w "$bestAPSSID" "$bestAPMAC"
            
            #Test if it is associated       
            assoc=`iw dev $INTERFACE link`
            if [[ "`echo $assoc | grep 'Not connected' | wc -l`" = "1" ]]; then
              if [[ "$VERBOSE" > "1" ]]; then
                echo "failed to connect to AP $bestAPSSID $bestAPMAC"
              fi
            else 
              
              if [[ "$VERBOSE" > "1" ]]; then
                dhclient -v $INTERFACE 2>&1
              else
                dhclient $INTERFACE 2>&1
              fi
            fi
          else
            if [[ "$VERBOSE" > "1" ]]; then
                echo `date "+%d/%m/%Y-%H:%M:%S"` "There is an AP to connect but with bad signal: $bestAPSSID $bestAPMAC"
            fi
          fi
        else
           if [[ "$VERBOSE" > "1" ]]; then 
              echo `date "+%d/%m/%Y-%H:%M:%S"` "There is no AP to connect"
           fi  
         fi
        
    else
      echo `date "+%d/%m/%Y-%H:%M:%S"` "There is a connection. Nothing to do"
    fi
    
    sleep $INTERVAL
done
