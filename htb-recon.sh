#!/bin/zsh

## in ~/.tmux.conf to enable mouse scrolling
## set -g mouse on
## set -g terminal-overrides 'xterm*:smcup@:rmcup@'

target=$1
name=$2
box=$3


if (($#==3));
then

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
  
  ## The Main Dashboard
  tmux new-window -d -t htb_recon -n DASH
  tmux split-window -h -t htb_recon:DASH
  tmux split-window -v -t htb_recon:DASH.0
  tmux split-window -v -t htb_recon:DASH.2

  ## The DNS Dashboard
  tmux new-window -d -t htb_recon -n DNS
  tmux split-window -h -t htb_recon:DNS.0

  ## VPN Window: Running Commands
  tmux send-keys -t htb_recon:VPN 'sudo openvpn ~/HackingProjects/hackthebox/lab.ovpn'

  ## Port Window: Running Commands
  ## An nmap session for initial ports
  ## masscan for all ports
  ## gobuster for directory enumeration, assuming a non-SSL web server
  ## ffuf for similar
  tmux send-keys -t htb_recon:DASH.0 'nmap -sC -sV -oN recon/initial_nmap.txt -v -Pn $target' 
  tmux send-keys -t htb_recon:DASH.1 'sudo masscan -p1-65535 -e tun0 -oL recon/allports.txt --rate=1000 -vv -Pn $target'
  tmux send-keys -t htb_recon:DASH.2 'gobuster dir -u http://$target -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -o recon/dirscan.txt'
  tmux send-keys -t htb_recon:DASH.3 'ffuf -w /usr/share/wordlists/dirb/big.txt -u http://$target/FUZZ | tee recon/ffuf.txt' 

  ## DNS Window: Running Commands
  tmux send-keys -t htb_recon:DNS.0 'echo "${target}\t${name}.htb"  | sudo tee -a /etc/hosts' 
  tmux send-keys -t htb_recon:DNS.1 'gobuster dns -d $name.com -w /usr/share/wordlists/dirb/common.txt -o recon/dnsscan.txt'

  ## Create notes in MarkDown, ready for VS Code
  echo "# Info" >> Notes.md
  echo "* IP: $target" >> Notes.md
  echo "* Box: $box" >> Notes.md
  echo "* Level: " >> Notes.md
  code  Notes.md

  echo "'tmux a -t htb_recon' to connect"
else
  echo "Usage: ./htb-recon.sh <IP> <Name_of_Machine> <OS> "
  echo "Example: ./htb-recon.sh 10.10.10.180 ServMon Windows"

fi
