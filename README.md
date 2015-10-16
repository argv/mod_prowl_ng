# mod_prowl_ng

eJabberd module - sends an API request to `Prowl` when defined user is offline. It is based on `Robert George` [mod_offline_prowl.erl](http://www.unsleeping.com/2010/07/31/prowl-module-for-ejabberd/).

# Requirements

- eJabberd lib- and header-files >= 15.02
- Prowl API key

# Installation

* modify "build.sh" ebin directory
* modify "Emakefile" header directory

`./build.sh`

* copy `ebin/mod_prowl_ng.beam` to eJabberd ebin directory

# Configuration

modules section ejabberd.yml

    mod_prowl_ng:
      ## "JID": "Prowl API key"
      "eris@xmpp.local":  "1143ffe24542c23c42c5c25f509e211ef17f0e0f"
      "fletz@xmpp.local": "2226ae94105d0c4ae191ed8b8a8e447cd77e9f9e"

