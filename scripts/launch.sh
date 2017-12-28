#!/bin/bash -x

get_from_consul () {
    for i in "${requires[@]}"
    do
        consul kv get --http-addr=consul:8500 $i
        while [ $? -ne 0 ]; do
            sleep 1
            consul kv get --http-addr=consul:8500 $i
        done
        eval "export $i=$(consul kv get --http-addr=consul:8500 $i)"

    done
}

get_pcimac_addr () {

    ifname=$1
    cid="$(sed -ne '/hostname/p' /proc/1/task/1/mountinfo | awk -F '/' '{print $6}' |tr -d " " )"
    cid="$cid-$ifname"
    eval "export $2=$(awk -F '"' '{print $4}' /sriov-cni/$cid)"
    eval "export $3=$(awk -F '"' '{print $8}' /sriov-cni/$cid)"
}



if [ $1 == "cp" ]
then
    cd /opt/ngic/bin
    echo "Configuring CP"
    # set the variables we provide
    SGW_S11_IP=$(netstat -ie | grep -A1 s11-net | tail -1 | awk '{print $2}' | tr -d addr:)
    CP_CPDP_IP=$(netstat -ie | grep -A1 cpdp-net | tail -1 | awk '{print $2}' | tr -d addr:)
    consul kv put --http-addr=consul:8500 SGW_S11_IP $SGW_S11_IP
    consul kv put --http-addr=consul:8500 CP_CPDP_IP $CP_CPDP_IP

    declare -a requires=( "SGW_S1U_IP" "MME_S11_IP" "DP_CPDP_IP" )

    # get the variables we require
    get_from_consul

    # get the rest of the variables
    . /opt/ngic/config/cp_config.cfg

    # update interface.cfg cp_comm_ip =
    sed -ri "s,(dp_comm_ip = ).*,\1$DP_CPDP_IP," ../config/interface.cfg
    sed -ri "s,(cp_comm_ip = ).*,\1$CP_CPDP_IP," ../config/interface.cfg

    # now run the binary
    ./ngic_controlplane  $EAL_ARGS -- $APP_ARGS

elif [ $1 == "dp" ]
then

    cd /opt/ngic/bin
    echo "Configuring DP"
    # if we are using sriov, -w pciAddr
    if [ -d "/sriov-cni" ]; then
        echo "================== SR-IOV FOUND ============"
        echo "TODO for now, manually put some dummy ips in consul"
        SGW_S1U_IP="2.2.2.2"
        SGW_SGI_IP="3.3.3.3"
        
        get_pcimac_addr s1u-net SGW_S1U_PCI S1U_MAC
        get_pcimac_addr sgi-net SGW_SGI_PCI SGI_MAC
        DEVICES="-w $SGW_S1U_PCI -w $SGW_SGI_PCI"


    else #dev --vdev af_packt
        echo "vdev (AF_PACKET)"
        # set the variables we provide
        SGW_S1U_IP=$(netstat -ie | grep -A1 s1u-net | tail -1 | awk '{print $2}' | tr -d addr:)
        SGW_SGI_IP=$(netstat -ie | grep -A1 sgi-net | tail -1 | awk '{print $2}' | tr -d addr:)
        S1U_MAC=$( netstat -ie | grep -B1 $SGW_S1U_IP | head -n1 | awk '{print $5}' )
        SGI_MAC=$( netstat -ie | grep -B1 $SGW_SGI_IP | head -n1 | awk '{print $5}' )

        DEVICES="--no-pci --vdev eth_af_packet0,iface=s1u-net --vdev eth_af_packet1,iface=sgi-net"
    fi

    DP_CPDP_IP=$(netstat -ie | grep -A1 cpdp-net | tail -1 | awk '{print $2}' | tr -d addr:)

    consul kv put --http-addr=consul:8500 SGW_S1U_IP $SGW_S1U_IP
    consul kv put --http-addr=consul:8500 SGW_SGI_IP $SGW_SGI_IP
    consul kv put --http-addr=consul:8500 DP_CPDP_IP $DP_CPDP_IP

    declare -a requires=( "RTR_SGI_IP" "CP_CPDP_IP" )

    # get the variables we require
    get_from_consul

    # update interface.cfg cp_comm_ip =
    sed -ri "s,(dp_comm_ip = ).*,\1$DP_CPDP_IP," ../config/interface.cfg
    sed -ri "s,(cp_comm_ip = ).*,\1$CP_CPDP_IP," ../config/interface.cfg

    # get the rest of the variables
    . /opt/ngic/config/dp_config.cfg

    # now run the binary

    ./ngic_dataplane  $EAL_ARGS -- $APP_ARGS

elif [ $1 == "traffic" ]
then
    echo "Configuring Traffic Container"
    if [ -d "/sriov-cni" ]; then
        echo "================== SR-IOV FOUND ============"
        RTR_SGI_IP=9.9.9.9
        MME_S11_IP=10.10.10.10
        ENB_S11_IP=11.11.11.11
    else #dev --vdev af_packt
        RTR_SGI_IP=$(netstat -ie | grep -A1 sgi-net | tail -1 | awk '{print $2}' | tr -d addr:)
        MME_S11_IP=$(netstat -ie | grep -A1 s11-net | tail -1 | awk '{print $2}' | tr -d addr:)

        # Requires its own ENB address (but does not need to share)
        ENB_S11_IP=$(netstat -ie | grep -A1 s1u-net | tail -1 | awk '{print $2}' | tr -d addr:)
    fi

    # set the variables we provide
    consul kv put --http-addr=consul:8500 RTR_SGI_IP $RTR_SGI_IP
    consul kv put --http-addr=consul:8500 MME_S11_IP $MME_S11_IP

    declare -a requires=( "SGW_S1U_IP" "SGW_SGI_IP" "SGW_S11_IP" )

    # get the variables we require
    get_from_consul

    # perform the traffic rewrites
    ./rewrite_pcaps.py $ENB_S11_IP $SGW_S11_IP $SGW_S1U_IP $SGW_SGI_IP
    sleep 3600

else
    echo "Unsupported $1"
fi
