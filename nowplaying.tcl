################################################
#################### ABOUT #####################
################################################
#
# NowPlaying-0.1 by Fredrik Bostrom
# for Eggdrop IRC bot
#
# Usage:
# !rp [username]
#   - gets the most recent entry from your
#     last.fm 'recent tracks' feed
#     and displays it
#   - username is your last.fm username 
#     (optional)
#   - if no username is supplied, the caller's 
#     nick is used as username
#
# !np
#   - connects to a linux machine running 
#     Amarok and gets the song playing there
#   - a passwordless ssh login for the user 
#     running eggdrop from the machine running 
#     eggdrop to the account running Amarok on 
#     the machine running Amarok have to be set
#     up for this to work
#
################################################
################# CONFIGURATION ##### ##########
################################################

# *** for nplocal ***
# path to the ssh-key for passwordless login
# to the remote host (required)
set sshkeypath "/home/eggdrop/.ssh/id_dsa"

# the hostname of the remote host
# (either full name, or alias. Required)
set hostname "kermit"

# username for the remote host (required)
set username "fredde"

################################################
######## DON'T EDIT BEOYND THIS LINE! ##########
################################################

package require http

bind pub - !rp pub:recentlyPlayed
bind pub n|n !np pub:nowPlaying

proc pub:recentlyPlayed {nick host handle chan text} {
    if {[llength $text] == 0} {
	set username $nick
    } else {
	set username $text
    }
    
    set lfmurl [string replace "http://ws.audioscrobbler.com/1.0/user/%/recenttracks.txt" 38 38 $username]
    #putlog $lfmurl
    set page [::http::data [::htlfmtp::geturl $lfmurl]]
    
    set lines [split $page \n]
    set time [clock format [lindex [split [lindex $lines 0] ","] 0] -format "%H:%M (%b %d)"]
    set song [lindex [split [lindex $lines 0] ","] 1]
    
    set res ""
    foreach i [split $song ""] {
        scan $i %c c
	#	if {$c<128} {append res $i} else {append res \\u[format %04.4X $c]}
	if {$c<128} {append res $i} else {append res "--"}
    }
    #putlog $song
    #putlog $res
    
    putserv "PRIVMSG $chan :$username played '$res' at $time"
}

proc pub:nowPlaying {nick host handle chan text} {
    global sshkeypath
    global username
    global hostname

    set data ""
    
    set file [open "| ssh -i $sshkeypath $username@$hostname DISPLAY=:0 dcop --user $username --all-sessions amarok player nowPlaying"]
    set data [string trim [read $file]]
    
    if { [catch {close $file} err] } {
	if {$err != "call failed"} {
	    putlog "Nowplayinglocal command failed: $err"
	}
    }
    putserv "PRIVMSG $chan :Now playing: $data"
}

###################################
putlog "Now playing script loaded!"
###################################
