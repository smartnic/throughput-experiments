#!/bin/bash


sudo ip link set dev ens3f0 xdp off
sudo ip link set dev ens3f1 xdp off

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

function run_program {
    program=$1
    if [[ "$program" = "xdp1" ]]; then
        sudo ./xdp1 -N ens3f0
    elif [[ "$program" = "xdp2" ]]; then
        sudo ./xdp2 -N ens3f0
    elif [[ $program = "xdp_pktcntr" ]]; then
        sudo ip link set dev ens3f0 xdp obj xdp_pktcntr.o sec xdp-pktcntr
        read -n 1 -s -r -p "Press any key to load the next program"
        echo ""
        sudo ip link set dev ens3f0 xdp off
        return
    elif [[ $program = "xdp_redirect" ]]; then
        sudo ./xdp_redirect -N ens3f0 -N ens3f1 
    elif [[ $program = "xdp_map_access" ]]; then
        sudo ./xdp_map_access -N ens3f0
    else 
        echo -e "${RED}Error${NC}: Program $program not recognized"
    fi
    sudo ip link set dev ens3f0 xdp off
    sudo ip link set dev ens3f1 xdp off
    read -n 1 -s -r -p "Press any key to load the next program"
    echo ""
}
# program is name of binary to execute
# elf_file given without the extension
# patched_dir is directory containing patched program
function load_and_run {
    program=$1
    elf_file=$2
    patched_dir=$3
    echo "Loading $program compiled by clang"
    cp O1/$elf_file.o . 
    run_program $program
    rm $elf_file.o
    cp O2/$elf_file.o . 
    run_program $program
    rm $elf_file.o
    cp O3/$elf_file.o . 
    run_program $program
    rm $elf_file.o
    patched_elf_file="${elf_file}0"
    for i in {1..16}; do
        current_elf=$patched_dir/$i/$patched_elf_file.o
        if [[ ! -f $current_elf ]]; then
            continue 
        fi
        cp $current_elf $elf_file.o
        run_program $program
        rm $elf_file.o
    done
    echo -e "${GREEN}**FINISH $program**${NC}"
}

load_and_run xdp1 xdp1_kern completed-programs/kernel_samples_xdp1_kern_xdp1_runtime_debug
load_and_run xdp2 xdp2_kern completed-programs/kernel_samples_xdp2_kern_xdp1_runtime_debug
load_and_run xdp_pktcntr xdp_pktcntr completed-programs/katran_xdp_pktcntr_runtime_debug
load_and_run xdp_redirect xdp_redirect_kern completed-programs/kernel_samples_xdp_redirect_runtime_debug
load_and_run xdp_map_access xdp_map_access_kern completed-programs/simple_fw_xdp_map_access_runtime_debug


