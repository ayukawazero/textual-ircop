textual-ircop
=============

IRCop Enhancements for Textual 5

Copyright (c) 2015 Jeffrey Clark

*** This project should be considered abandoned. ***

Usage:
    Copy the bundle and .XML files into your Textual 5 extensions
folder and restart textual.  Modify filters in the .XML file as needed.

Commands:

/RELOADFILTERS
- Reloads the .XML file and updates any filters

/SHOWFILTERS
- Returns a list of filters in the system (mostly for debugging)

/LOCOPS <message>
/CHATOPS <message>
/GLOBOPS <message>
- Sends the appropriate commands to the server (Mostly useful with bahamut ircd)

Filters use the following format:

<filter enabled="yes">
<expression>\*\*\* Client -- Client connecting: (.*)</expression>
<format color="2" tag="C">Connecting: @M_1@</format>
</filter>

enabled: (yes|no|halt)
    This attribute determines if the filter should be processed or not.  Setting
to "halt" will prevent the matching notice from appearing altogether.

expression:
    Regular expression for the server notice you wish to filter.

format:
    The reformatted notice that will appear in the @Operator window.  Use @M_#@ to
display the corresponding match from the regular expression.

color:
    This attribute specifies the color for the line in the @Operator window.  Uses the
standard mIRC-style colors.

tag:
    This attribute specifies the tag to appear within the [- -] prefix for the line in
the @Operator window.
