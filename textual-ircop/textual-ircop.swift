//
//  textual-ircop.swift
//  textual-ircop
//
//  Created by Jeffrey Clark on 8/6/14.
//  Copyright (c) 2014 Jeffrey Clark. All rights reserved.
//

import Foundation

//Regex Extension from https://gist.github.com/KingOfBrian/8d2c6d85cb4079aabde6

infix operator =~ {}

func =~ (input: String, pattern: String) -> [String]? {
    let regex = NSRegularExpression(pattern: pattern, options: .CaseInsensitive, error: nil)
    
    let results = regex.matchesInString(input,
        options: nil,
        range: NSMakeRange(0, countElements(input))
        )! as [NSTextCheckingResult]
    
    if (results.count > 0) {
        var values:Array<String> = []
        
        for result in results {
            for i in 0..<result.numberOfRanges {
                let range = result.rangeAtIndex(i)
                
                let loc = (input.string as NSString).substringFromIndex(range.location)
                values.append((loc.string as NSString).substringToIndex(range.length))
                
            }
            
        }
        return values
    } else {
        return nil
    }
}



class TPI_IRCopPlugin: NSObject, THOPluginProtocol
{
    let dataPath = TPCPathInfo.customExtensionFolderPath()
    let dataFile = ("ircop-filters.xml")
    
    var filterArray: [OperFilter] = []

    
    /* 
        Open and parse the XML configuration file, placing the results into filterArray
    */
    func loadFilterSet(client :IRCClient) {
        let filterParser = SwiftXMLParser(fromFileAtPath: "\(dataPath)/\(dataFile)")
        
        filterParser.start()
        filterArray = filterParser.getParsedItems()
        
        self.writeToWindow(client, text: "Loaded \(filterArray.count) filters in \(filterParser.getLastDuration()) seconds.")

    }
    

    /*
        Displays a list of loaded filters into the @Operator window.  Mostly for debugging.
    */
    func showFilters(client: IRCClient) {
        for of in filterArray {
            writeToWindow(client,text:"Expression: \(of.expression)")
        }
    }


    
    /*
        Creates the @Operator window for us to send messages to.
    */
    func buildOperatorWindow(client :IRCClient) {
        worldController().createPrivateMessage("@Operator", client: client)
    }
    
    
    /*
        Intercepts all data coming from server.  NOTICE messages will be set to the plugin 
        handler, everything else will just be passed along.
    */
    func interceptServerInput(input: IRCMessage!, `for` client: IRCClient!) -> IRCMessage! {
        let commandValue = (input.command as String);
        //let message = input.paramAt(1);
        
        switch (commandValue) {
        case "NOTICE":
            return handleIncomingNoticeCommand(client,input: input);
        default:
            return input;
        }
    }
    
    
    /*
        Run server notices against filter array and reformat matches.  Returns nil if there's a
        handled match, and returns the original IRCMessage if no filter is found.
    */
    func handleIncomingNoticeCommand(client :IRCClient, input: IRCMessage!) -> IRCMessage!
    {
        if (filterArray.count < 1) { self.loadFilterSet(client) }
        var mParamString = "";
        let messageRecieved = input.paramAt(1)
        
        if (messageRecieved.hasPrefix("***")) {   //We should be able to safely assume this is a server notice
            for of in filterArray {
                let isEnabled = of.enabled.lowercaseString
                if isEnabled == "yes" || isEnabled == "halt" {
                    if var matches = messageRecieved =~ of.expression {
                        if isEnabled == "halt" { return nil }
                        
                        let formattedTag = "[-\u{0003}\(of.color)\(of.tag)\u{0003}-] \u{0003}\(of.color)"
                        
                        var formattedString = of.format;//result;
                        for i in 0..<matches.count {
                            formattedString = formattedString.stringByReplacingOccurrencesOfString("@M_\(i)@", withString: matches[i], options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
                            
                        }
                        //Apparently we need to process colors by hand.
                        let uCodes: [String: String] = ["@B@": "\u{0002}", "@I@": "\u{001D}", "@U@": "\u{001F}", "@C@": "\u{0003}"]
                        
                        for (at,uc) in uCodes {
                            formattedString = formattedString.stringByReplacingOccurrencesOfString(at, withString:uc, options: NSStringCompareOptions.LiteralSearch, range:nil)
                        }
                        
                        self.writeToWindow(client, text: formattedTag+formattedString)
                        
                        return nil; //We've handled the notice, Textual doesn't need to process it further.
                    }
                }
            }
        }
        return input; //Nothing matched, let Textual handle it.
    }
    
    
    /*
        Writes text to the @Operator window, creating the window if it does not exist.
    */
    func writeToWindow(client: IRCClient, text: String)
    {
        if (client.findChannel("@Operator") == nil) { self.buildOperatorWindow(client) }
        
        client.iomt().print(client.findChannel("@Operator"), type:TVCLogLineDebugType, nickname:nil, messageBody: text, command: TVCLogLineDefaultRawCommandValue)
        client.findChannel("@Operator").treeUnreadCount++
    }
    
    
    /*
        Returns an array of user commands supported, expecting all caps.  
        These commands will show in the plugin dialog.
    */
    func pluginSupportsUserInputCommands() -> (NSArray)
    {
        return ["RELOADFILTERS","SHOWFILTERS","LOCOPS"]
    }
    
    
    /*
        Handles user commands supported by the plugin.
        Deprecated: Should be replaced with userInputCommandInvokedOnClient
    */
    func messageSentByUser(client: IRCClient, message: String, command: String)
    {
        switch (command) {
            case "RELOADFILTERS":
                self.loadFilterSet(client);
            case "SHOWFILTERS":
                self.showFilters(client);
            case "LOCOPS":
                client.sendLine("locops :\(message)")
            case "GLOBOPS":
                client.sendLine("globops :\(message)")
            case "CHATOPS":
                client.sendLine("chatops :\(message)")
            default:
                return;
        }
    }
    
}