# mailconfdiscovery

Collects mail system related configuration, including
* OS version
* Linux Distibution name
* cPanel version
* Exim version and configuration (/etc/exim.conf)
* Exim mail logs (exim\_mainlog, exim\_paniclog, exim\_rejectlog)

### To run 
`$ bash discovery`

## Result
As result script produces file report in `mailconfdiscovery` directory including following files:

- `exim.conf.copy`  
- `exim_mainlog-noemail`  
- `exim_paniclog-noemail`  
- `exim_rejectlog-noemail`  
- `report.txt`

