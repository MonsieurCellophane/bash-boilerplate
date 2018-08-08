#!/bin/env bash
# Exit on error. Append "|| true" if you expect an error.
set -o errexit
# Exit on error inside any functions or subshells.
set -o errtrace
# Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
set -o nounset
# Catch the error in case mysqldump fails (but gzip succeeds) in `mysqldump |gzip`
set -o pipefail
# Turn on traces, useful while debugging but commented out by default
#set -o xtrace
#PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
function _cleanup_before_exit () {
  info "Cleaning up. Done"
}
trap _cleanup_before_exit EXIT
# requires `set -o errtrace`
_err_report() {
    local error_code
    error_code=${?}
    die "Error in ${0} in function ${1} on line ${2}" ${error_code}
}
trap '_err_report "${FUNCNAME:-.}" ${LINENO}' ERR
#
VER=0.1
AUTHOR="Monsieur Cellophane <MrC3llophane@gmail.com>"
NAME=$(basename "$0")

sa_usage () { 	echo "Usage: $NAME [-d [-d -d] ] [-g group] dir " ; }
usage () {
	echo "$NAME $VER $AUTHOR"
	echo
	sa_usage
	echo
	echo "        -d   set debug -repeat for higher levels   "
	echo "        -v   verbose                               "
	echo "        -l logfile: all messages go to logfile     "
	echo "        -y   answer yes to questions               "
	echo "        -T   Turn on tracing                       "
	echo "        -x   an example additional arg"
	echo "whatever: what ever"
	echo
	echo "See also: man boilerplate"
	echo
}

##################################
# Colors
##################################

NO_COLOR=0
declare -A _cl
_cl[gray]="$(tput setaf 0)"  
_cl[red]="$(tput setaf 1)"   
_cl[green]="$(tput setaf 2)" 
_cl[yellow]="$(tput setaf 3)"
_cl[blue]="$(tput setaf 4)"  
_cl[purple]="$(tput setaf 5)"
_cl[cyan]="$(tput setaf 6)"  
_cl[white]="$(tput setaf 7)" 
_cl[reset]="$(tput sgr0)"    
_cl[bold]="$(tput bold)"     
_cl[rev]="$(tput rev)"       

_cl[SAY]="${_cl[bold]}${_cl[white]}"
_cl[ASK1]="${_cl[green]}"
_cl[ASK2]="${_cl[rev]}${_cl[green]}"
_cl[TRACE]="${_cl[rev]}${_cl[green]}"
_cl[DEBUG]="${_cl[bold]}${_cl[gray]}"
_cl[VERBOSE]="${_cl[rev]}${_cl[cyan]}"
_cl[INFO]="${_cl[rev]}${_cl[blue]}"
_cl[WARNING]="${_cl[rev]}${_cl[yellow]}"
_cl[ERROR]="${_cl[rev]}${_cl[purple]}"
_cl[FATAL]="${_cl[rev]}${_cl[red]}"

col()  {
    [[ x$NO_COLOR == x1 ]] && return 0
    echo "${_cl[$1]}"
}

##################################
# Tracing
##################################
_trace() {
    # call with no arg to turn off.
    local on=$1
    if [[ x$on == x ]] ; then
	set +x
    else
	PS4='+${_cl[TRACE]}(${BASH_SOURCE}:${LINENO})${_cl[reset]}: ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
	set -o xtrace
    fi
    return 0
}
tron() { _trace 'on' ; }
troff() { _trace ;     }

##################################
# Debug Messages
##################################
_dlev() {
    local nlev=$1
    shift
    [[ $nlev -ge $_DEBUG ]] || return 0
    local level="DEBUG"
    local color=${_cl[$level]}
    local col_reset=${_cl[reset]}
    
    if [[ x$NO_COLOR == x1 ]]; then
	color=''
	col_reset=''
    fi
    # Read everything else
    local log_line=""
    local td
    td="$(date +'%Y-%m-%d %H:%M:%S %Z')"
    
    local fcn="$NAME(${BASH_LINENO[2]:-}):${FUNCNAME[2]}(${BASH_LINENO[1]:-})"
    while IFS=$'\n' read -r log_line; do
	#td=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
	echo -e "${td} ${color}$(printf "[%-7s(%d)]" "${level}" "$nlev") ${fcn}${col_reset} ${log_line}" | $_LOG 1>&2
    done <<< "${@:-}"
    
}
d0() { _dlev 0 "${@}" ; true   ; }
d1() { _dlev 1 "${@}" ; true   ; }
d2() { _dlev 2 "${@}" ; true   ; }
# Add more levels as needed

##################################
# Logging
##################################
_log() {
    local level="$1"
    shift
    local color=${_cl[$level]}
    local col_reset=${_cl[reset]}
    
    if [[ x$NO_COLOR == x1 ]]; then
	color=''
	col_reset=''
    fi
    # Read everything else
    local log_line=""
    local td
    td="$(date +'%Y-%m-%d %H:%M:%S %Z')"
    
    local fcn="$NAME(${BASH_LINENO[2]:-}):${FUNCNAME[2]}(${BASH_LINENO[1]:-})"
    while IFS=$'\n' read -r log_line; do
	#td=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
	echo -e "${td} ${color}$(printf "[%-7s]" "${level}") ${fcn}${col_reset} ${log_line}" | $_LOG 1>&2
    done <<< "${@:-}"
}
info() { _log "INFO" "${@}" ; true   ; }
warn() { _log "WARNING" "${@}" ; true   ; }
err()  { _log "ERROR"   "${@}" ; true   ; }
die()  { _log "FATAL"   "${@}" ; exit "${@:$#}" ; }
# also for last; do true; done; exit $last  to get to last arg.
# see https://stackoverflow.com/questions/1853946/getting-the-last-argument-passed-to-a-shell-script

#######################################
# Non log stamped messaging/interaction
#######################################
say()  {
    local color
    color="$( col 'SAY' )"
    local col_reset
    col_reset="$( col 'reset' )"
    # Read everything else
    local log_line=""
    while IFS=$'\n' read -r log_line; do
	#td=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
	echo -e "${color}${log_line}${col_reset}" | $_LOG 1>&2
    done <<< "${@:-}"
}
vbs() {
    [[ x${opt_v:-} != x ]]  || return 0
    _log "VERBOSE" "${@}" ; true   ; 
}


#######################################
# General Purpose
#######################################
#http://stackoverflow.com/questions/3915040/bash-fish-command-to-print-absolute-path-to-a-file
abspath() {
    local curdir
    local retval
    
    curdir=$(pwd)
    if [[ -d "$1" ]]; then
	retval=$( cd "$1" || return ; pwd )
    else 
	retval=$( cd "$( dirname "$1" )" || return ; pwd )/$(basename "$1")
    fi
    cd "$curdir" || return
    echo "$retval"
}

#usage: if ask "Do you [y/n]" y; then this; else that; fi
# will write
#  Do you [y/n]?> 
# and return true if use enters y
function ask() {
    local cl1
    cl1="$( col 'ASK1' )"
    local cl2
    cl2="$( col 'ASK2' )"
    local clr
    clr="$( col 'reset' )"
    if [[ x${ASSUME_YES:-} != x ]]; then /bin/true; return ; fi
    echo -en "${cl1}${1}${clr}  ${cl2}$3${clr}> " 1>&2 
    read -r ans
    if [[ x$ans == x$2 ]]; then
	/bin/true
    else
	/bin/false
    fi
}
	 
#######################################
# Switch processing
#######################################

# getopts optstring NAME [args]
#
#    getopts is used by shell procedures to parse positional
#    parameters.  optstring contains the option characters to be
#    recognized; if a character is fol- lowed by a colon, the option
#    is expected to have an argument, which should be separated from
#    it by white space.  The colon and question mark characters may
#    not be used as option characters.  Each time it is invoked,
#    getopts places the next option in the shell variable name,
#    initializing name if it does not exist, and the index of the
#    next argument to be processed into the variable OPTIND.  OPTIND
#    is initialized to 1 each time the shell or a shell script is
#    invoked.  When an option requires an argument, getopts places
#    that argument into the variable OPTARG.  The shell does not
#    reset OPTIND auto- matically; it must be manually reset between
#    multiple calls to getopts within the same shell invocation if a
#    new set of parameters is to be used.

#    When the end of options is encountered, getopts exits with a
#    return value greater than zero.  OPTIND is set to the index of
#    the first non-option argu- ment, and name is set to ?.

#    getopts normally parses the positional parameters, but if more
#    arguments are given in args, getopts parses those instead.

#    getopts can report errors in two ways.  If the first character
#    of optstring is a colon, silent error reporting is used.  In
#    normal operation diagnostic messages are printed when invalid
#    options or missing option arguments are encountered.  If the
#    variable OPTERR is set to 0, no error messages will be
#    displayed, even if the first character of optstring is not a
#    colon.

#    If an invalid option is seen, getopts places ? into name and, if
#    not silent, prints an error message and unsets OPTARG.  If
#    getopts is silent, the option character found is placed in
#    OPTARG and no diagnostic message is printed.

#    If a required argument is not found, and getopts is not silent,
#    a question mark (?) is placed in name, OPTARG is unset, and a
#    diagnostic message is printed.  If getopts is silent, then a
#    colon (:) is placed in name and OPTARG is set to the option
#    character found.
_LOG='cat'
_DEBUG=-1
_TRACING=''

while getopts dvhyTl:q:w:cr:nNFSAEi:f:l:m:p:s:x:C opt ; do
    # shellcheck disable=2086
    case "$opt" in
	# STANDARD
	d)
	    # test if numeric
	    opt_v=1
	    if [[ "$_DEBUG" =~ ^-?[0-9]+$ ]]; then
	     # also [ "$_DEBUG" -eq "$_DEBUG" ] (mind the single brackets, though)
		_DEBUG=0
	    else
		_DEBUG=$(( "$_DEBUG" + 1 ))
	    fi
	    ;;
	T)
	    # Turn on traces, useful while debugging but commented out by default
	    #set -x
	    _TRACING=1
	    ;;
	
	l) _LOG="tee -a $OPTARG"
	   LOGFILE=$OPTARG
	   ;;
	y) ASSUME_YES=1      ;;
	v) opt_v=1 ;;
	# EXAMPLES
	c|C) eval $opt="yes" ;;
	q|w|r|x) eval $opt="$OPTARG" ;;
	n|N|F|S|A|E) topt="$topt -$opt" ;;
	i|p|s) topt="$topt -$opt $OPTARG" ;;
	f|m) ttl="$OPTARG" ; echo "$ttl" ;;
	# UNKNOWN (and -h)
	?) usage; exit ;;
    esac
done

#Color schemes
if [[ x${LOGFILE:-} == x && -t 1 && -t 2 ]]; then
    NO_COLOR=0
else
    #disable coloring
    NO_COLOR=1
fi
# Tracing starts, if requested
[[ x$_TRACING != x ]] && tron

# leave nonswitch args for later
# shellcheck disable=SC2004
shift $(( $OPTIND - 1 ))

#######################################
#
# TESTING boilerplate
#
#######################################

d0 " debug message"
d1 " debug deeper"

foo() {
    info "testing funcname"
    info "scalar 0: ${FUNCNAME[0]}"
    info "scalar 1: ${FUNCNAME[1]}"
    info "array: " "${FUNCNAME[@]}"
	
}

foo

vbs " verbose info"
info "Info\\n" "\\t\\t\\t\\t\\t$(col 'yellow')Message$(col 'reset' )"
warn " warning message"
err " an error "
say "A\\n multiline\\n  statement.\\n   Is\\n    it\\n     not nice?"
if ask "Continue?" "y" "[y/n]" ; then
    say "OK!" 1>&2
else
    echo "Abort on gratuitous error" 1>&2
    foobar
fi

die "It's a killer!" 15
