#!/bin/zsh

## in ~/.tmux.conf to enable mouse scrolling
## set -g mouse on
## set -g terminal-overrides 'xterm*:smcup@:rmcup@'

target=$1
name=$2
box=$3

if (($# != 3));
then
  echo "Usage: ./htb-recon.sh <IP> <Name_of_Machine> <OS> "
  echo "Example: ./htb-recon.sh 10.10.10.180 ServMon Windows"
  exit 1
fi

## Create directory
mkdir -p ~/HackingProjects/hackthebox/$name
mkdir -p ~/HackingProjects/hackthebox/$name/recon
mkdir -p ~/HackingProjects/hackthebox/$name/loot
mkdir -p ~/HackingProjects/hackthebox/$name/exploits

## Create session
cd ~/HackingProjects/hackthebox/$name
export target
export box
export name

## Create Tmux Session
tmux new -s htb_recon -d
  
## The VPN Window
tmux rename-window -t htb_recon VPN
  
## The Ports
tmux new-window -d -t htb_recon -n PORTS
tmux split-window -h -t htb_recon:PORTS
tmux split-window -v -t htb_recon:PORTS.1

## The Directories
tmux new-window -d -t htb_recon -n DIRS
tmux split-window -h -t htb_recon:DIRS

## The DNS
tmux new-window -d -t htb_recon -n DNS
tmux split-window -h -t htb_recon:DNS
tmux split-window -v -t htb_recon:DNS.0
tmux split-window -v -t htb_recon:DNS.2

## Scratchpad
tmux new-window -d -t htb_recon -n SCRATCH
tmux split-window -h -t htb_recon:SCRATCH

## VPN Window: Running Commands
tmux send-keys -t htb_recon:VPN 'sudo openvpn ~/HackingProjects/hackthebox/lab.ovpn'

## Scan for ports - nmap for quick scan, masscan for deep scan
tmux send-keys -t htb_recon:PORTS.0 'nmap -T4 -sC -sV -oN recon/ports_initial_nmap.txt -v -Pn $target' 
tmux send-keys -t htb_recon:PORTS.1 'sudo masscan -p1-65535 -e tun0 -oL recon/ports_full_masscan.txt --rate=1000 -vv -Pn $target'
tmux send-keys -t htb_recon:PORTS.2 'nmap -sU -F --min-rate 1000 -n -Pn --max-retries 2 -oN udpFast.txt $target'

## Scan for directories
tmux send-keys -t htb_recon:DIRS.0 'gobuster dir -u http://${name}.htb -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -o recon/dir_gobuster.txt'
tmux send-keys -t htb_recon:DIRS.1 'ffuf -w /usr/share/wordlists/dirb/big.txt -u http://${name}.htb/FUZZ | tee recon/dir_ffuf.txt' 

tmux send-keys -t htb_recon:DIRS.1 'ffuf -w directory…. -u http://${name}.htb/FUZZ -recursion -e .txt,.php,.html,.bak,.jar,.war,.backup,._backup | tee recon/dir_ffuf.txt'

## DNS Window: Running Commands
tmux send-keys -t htb_recon:DNS.0 'echo "${target}\t${name}.htb"  | sudo tee -a /etc/hosts' 
tmux send-keys -t htb_recon:DNS.1 'dig any ${name}.htb @${target}' 
tmux send-keys -t htb_recon:DNS.2 'gobuster dns -d ${name}.htb -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-20000.txt -o recon/dns_gobuster.txt'
tmux send-keys -t htb_recon:DNS.3 'wfuzz -w /usr/share/wordlists/seclists/Discovery/DNS/subdomains-top1million-20000.txt -u http://${name}.htb/ -H "Host: FUZZ.${name}.htb" --hc 301,302 -f recon/dns_wfuzz.txt'

## Create notes in MarkDown, ready for VS Code
echo "# Info" >> Notes.md
echo "* Name: $name" >> Notes.md
echo "* IP: $target" >> Notes.md
echo "* Box: $box" >> Notes.md
echo "* Level: " >> Notes.md
code  Notes.md

echo "Connecting via:"
echo "tmux a -t htb_recon"

tmux a -t htb_recon
