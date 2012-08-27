#!/usr/bin/env python

import ConfigParser
import os

def readConfig(section):

    #
    # Check environment variable first, then $HOME/.aludra.conf,
    # then /etc/aludra.conf
    #

    configfile = os.getenv('ALUDRA_CONFIG')
    if configfile is None:
        configfile = os.path.join(os.getenv('HOME'), '.aludra.conf')
        if not os.access(configfile, os.R_OK):
            configfile = '/etc/aludra.conf'
            if not os.access(configfile, os.R_OK):
                return None

    Config = ConfigParser.ConfigParser()
    Config.read(configfile)

    connectStr = ''
    options = Config.options(section)
    for option in options:
        try:
            value = Config.get(section, option)
            if value == -1:
                DebugPrint("skip: %s" % option)
            else:
                connectStr = connectStr + "%s=%s " % (option, value)
        except:
            print("exception on %s!" % option)
    return connectStr
