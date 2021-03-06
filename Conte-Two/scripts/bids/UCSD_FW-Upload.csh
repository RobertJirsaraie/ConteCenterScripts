#!/usr/bin/expect
#################

set UPLOAD [lindex $argv 0]
set LAB [lindex $argv 1]
set PROJECT [lindex $argv 2]

########################################################
### Transfer Files From the Local Server To Flywheel ###
########################################################

spawn fw import folder $UPLOAD --group "$LAB" --project "$PROJECT"
expect "Confirm upload? (yes/no):"
send "yes\n"
interact

###################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡ #####
###################################################################################
