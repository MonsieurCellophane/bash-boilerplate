# bash-boilerplate

My bash boilerplate.

Some ideas (mostly on set -o, trapping and tracing) from: github.com:kvz/bash3boilerplate.git

To trim  and use as you see fit.

Main features:

## CLI processing

  * Automatic handling of log file
  * Command line switches scaffolding in place
  * Documentation scaffolding in place
  
## Debug features
  
  * Detailed (timestamped, line referenced, colored) tracing - activated by CLI switch or inline
  * Multilevel (timestamped, line referenced, colored) debug messages -  activated by CLI switch 

## Logging

  * All logging goes to STDERR/logfile. STDOUT is preserved for machine readable output
  * Colored, timestamped, line referenced logging
  * Colored messaging

## Other

  * Coloring is automatically turned off if messages go to (log)file or a pipe.
  * Error trapping
  * Following shellcheck best practices

## TODO

  * Log to syslog



