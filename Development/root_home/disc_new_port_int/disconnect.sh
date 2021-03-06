#/****************************************************************************/
#/*                                WANem 4                                   */
#/****************************************************************************/
#/*        COPYRIGHT (c) 2020 Tracy S. Fitch All Rights Reserved             */
#/*                                                                          */
#/*                                                                          */
#/* WANem is a WAN emulation tool Conceptualized and developed by Innovation */
#/* LAB TCS. We thank the open source community as we have taken the inspira */
#/* tion from the Netem, the open source network emulator.                   */
#/*                                                                          */
#/*                                                                          */
#/****************************************************************************/
#/****************************************************************************/
#/*   Original Author : Manoj Nambiar, TCS Innovation Lab Performance Engg.  */
#/*   Date            : March 2007                                           */
#/*   Synopsis        : disconnect.sh                                        */
#/*   Description     :                                                      */
#/*                                                                          */
#/*   Modifications   :                                                      */
#/*     2020-06-01  Tracy S. Fitch                                           */
#/*                 - netfilter/ no longer under ipv4 in /proc/sys/net/      */
#/****************************************************************************/
#/*                                                                          */

WRKDIR=$1

$WRKDIR/kill_disc.sh 
export PATH=$PATH:/usr/local/sbin:/sbin:/bin:/usr/bin
trap clean_up SIGHUP SIGINT SIGTERM 

function clean_up {
    # Perform program exit housekeeping
    echo "Brutus!"
    iptables -F FORWARD
    exit
}

iptables -F FORWARD 
export LD_LIBRARY_PATH=/usr/local/lib
modprobe ip_conntrack

# assuming this does not change while I am running
export timeout=`cat /proc/sys/net/netfilter/ip_conntrack_tcp_timeout_established`
nohup awk -f $WRKDIR/disco.awk -v net_ttl=$timeout -v disc_dir=$WRKDIR $WRKDIR/input.dsc &
