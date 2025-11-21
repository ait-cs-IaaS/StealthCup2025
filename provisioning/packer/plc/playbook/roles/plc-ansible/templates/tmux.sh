#!/bin/bash

project_path="{{ plc_dest }}"
session="{{ plc_tmux_session }}"
window="{{ plc_tmux_window }}"

tmux has-session -t "plc" 2> /dev/null
if [ $? == "1" ]
then
        echo "Starting session..."
	command -v tmuxinator
        if [ $0 == 0 ]
        then
                tmuxinator start "plc" --no-attach
        else
                tmux new-session -s "plc" -d
        fi
fi

tmux select-window -t "plc" 2> /dev/null
if [ $? == "1" ]
then
	echo "Create window"
	tmux new-window -n "plc"
fi

tmux send-keys -t "plc" "/bin/bash /home/ubuntu/plc/startup.sh" C-m
