#!/bin/zsh

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
  tmux split-window -v -t VPN
  tmux split-window -h -t htb_recon:VPN.0
  ## The Main Dashboard
  tmux new-window -d -t htb_recon -n DASH
  tmux split-window -h -t htb_recon:DASH.0
  tmux split-window -v -t htb_recon:DASH.1
  tmux split-window -v -t htb_recon:DASH.0

  ## Running Commands
  tmux send-keys -t htb_recon:VPN.0 'sudo openvpn ~/HackingProjects/hackthebox/lab.ovpn' 

  tmux send-keys -t htb_recon:DASH.0 'nmap -sC -sV -oN recon/initial_nmap.txt -v -Pn $target' 
  tmux send-keys -t htb_recon:DASH.1 'sudo masscan -p1-65535 -e tun0 -oL recon/allports.txt --rate=1000 -vv -Pn $target'
  tmux send-keys -t htb_recon:DASH.2 'gobuster dir -u http://$target -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -o recon/dirscan.txt'
  tmux send-keys -t htb_recon:DASH.3 'ffuf -w /usr/share/wordlists/dirb/big.txt -u http://$target/FUZZ | tee recon/ffuf.txt' 

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
