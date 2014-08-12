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
    
    @IBOutlet var ourView:NSView! = NSView()
    func pluginPreferencesPaneView() -> (NSView)
    {
        if (self.ourView == nil) {
            if (NSBundle.mainBundle().loadNibNamed("ircop-filters-config", owner: self, topLevelObjects: nil) == nil) {
                NSLog("Unable to open preference pane")
            }
        }
        return self.ourView;
    }
    
    func pluginPreferencesPaneMenuItemName() ->(NSString)
    {
        return "IRCop Extensions"
    }
    
    
    
    /*
        TODO: I dislike how this file/path is hardcoded and named.  I'd like to get more elaborate
            in the future.  Possibly support multiple filter files, configured through the GUI.  Maybe.
    */

    let dataFile = NSHomeDirectory().stringByAppendingPathComponent("Documents/dalnet-filters.xml");
    //var filterExpressions = [String:String]()
    
    var filterArray: [OperFilter] = []
    
    
    
    func loadFilterSet(client :IRCClient) {
        //let fileString = String.stringWithContentsOfFile(self.dataFile, encoding: NSUTF8StringEncoding, error: nil) as String!
        
        let filterParser = SwiftXMLParser(fromFileAtPath: self.dataFile)
        //let fileString = String.stringWithContentsOfFile(path, encoding: NSUTF8StringEncoding, error: nil) as String!
        //println(fileString)
        
        filterParser.start()
        filterArray = filterParser.getParsedItems()
        
        self.writeToWindow(client, text: "Loaded \(filterArray.count) filters in \(filterParser.getLastDuration()) seconds.")
        //myParser[0]
//        myParser.displayItems()
        
        
        
        
        
        /*
        if (fileString != nil) {
            let lines = fileString.componentsSeparatedByString("\n") as [String];
            
            self.filterExpressions =  [String: String]()
            
            for l in lines {
                if (!l.hasPrefix("#")) {
                    var tmpString = l.componentsSeparatedByString("🐶") as [String]; //Yes, we're using a dog to tokenize.
                    if (tmpString.count == 2) {
                        self.filterExpressions[tmpString[0]] = tmpString[1];
                    }
                }
            }
            self.writeToWindow(client, text: "Reloading \(self.dataFile)")
        } else {
            self.writeToWindow(client, text: "Unable to open \(self.dataFile)")
        }*/
    }
    
    func showFilters(client :IRCClient) {
        for of in filterArray {
            writeToWindow(client,text:"Expression: \(of.expression)")
        }
        /*
        for (regex,filter) in self.filterExpressions {
            self.writeToWindow(client,text:"Regex: \(regex) - Filter: \(filter)");
        }*/
    }
    
   /*
    - (NSView *)pluginPreferencesPaneView
    {
    if (self.ourView == nil) {
    if ([NSBundle loadNibNamed:@"PreferencePane" owner:self] == NO) {
    NSLog(@"TPI_PrefsTest: Failed to load view.");
    }
    }
    
    return self.ourView;
    }
    
    - (NSString *)pluginPreferencesPaneMenuItemName
    {
    return @"My Test Plugin";
    }*/
    
    
    
    func pluginSupportsServerInputCommands() -> (NSArray)
    {
        //We're accepting incoming data for NOTICE.  Not sure if this is needed with the intercept call.
        
        /* Accept all incoming server data corresponding to the
        commands PRIVMSG and NOTICE. The plugin will perform
        different actions for each value. */
        
        return ["notice"]
    }
    
    func buildOperatorWindow(client :IRCClient) {
        //client.findChannelOrCreate("@Operator",isPrivateMessage:true)
        
        worldController().createPrivateMessage("@Operator", client: client)
    }
    
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
    
    
    //func handleIncomingNoticeCommand(client :IRCClient, sender: NSDictionary, message: NSDictionary)
    func handleIncomingNoticeCommand(client :IRCClient, input: IRCMessage!) -> IRCMessage!
    {
        if (filterArray.count < 1) { self.loadFilterSet(client) }
        var mParamString = "";
        let messageRecieved = input.paramAt(1)
        
        if (messageRecieved.hasPrefix("***")) {
        //if (messageRecieved.substring(0,length: 3) == "***") {
            //We should be able to safely assume this is a server notice
            
            for of in filterArray {
            
            //for (expression, result) in self.filterExpressions {
                if of.enabled.lowercaseString=="yes" {
//                    writeToWindow(client,text:"\(messageRecieved) vs. \(of.expression)")
                if var matches = messageRecieved =~ of.expression {
                    if of.enabled.lowercaseString == "halt" { return nil }
                    
                    //if (result == "@HALT@") { return nil; }
                    
                    var formattedString = of.format;//result;
                    for i in 0..<matches.count {
                        
                        formattedString = formattedString.stringByReplacingOccurrencesOfString("@M_\(i)@", withString: matches[i], options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
                        
                    }
                    
                    //Apparently we need to process colors by hand.
                    let uCodes: [String: String] = /*["@BOLD@": "\u{0002}", "@ITALIC@": "\u{001D}", "@UNDERLINE@": "\u{001F}", "@COLOR@": "\u{0003}",*/ ["@B@": "\u{0002}", "@I@": "\u{001D}", "@U@": "\u{001F}", "@C@": "\u{0003}"]
                    
                    for (at,uc) in uCodes {
                        formattedString = formattedString.stringByReplacingOccurrencesOfString(at, withString:uc, options: NSStringCompareOptions.LiteralSearch, range:nil)
                    }
                    
                    self.writeToWindow(client, text: formattedString)
                    
                    return nil; //We've handled the notice, Textual doesn't need to process it further.
                }
                }
            }
            
        }
        return input; //Nothing matched, let Textual handle it.
    }
    
    func writeToWindow(client: IRCClient, text: String)
    {
        //var chan: IRCChannel = client.findChannel("@Operator")
        
        //Write to the server window.  This should eventually write to the @Operator window.
        if (client.findChannel("@Operator") == nil) { self.buildOperatorWindow(client) }
        
        client.iomt().print(client.findChannel("@Operator"), type:TVCLogLineDebugType, nickname:nil, messageBody: text, command: TVCLogLineDefaultRawCommandValue)
        client.findChannel("@Operator").treeUnreadCount++
    }
    
    func pluginSupportsUserInputCommands() -> (NSArray)
    {
        //Simply returns a list of the user commands supported.  They will show in the plugin dialog.
        return ["RELOADFILTERS","SHOWFILTERS"]
    }
    
    
    
    func messageSentByUser(client: IRCClient, message: String, command: String)
    {
        //Supposedly this is deprecated and should be replaced with userInputCommandInvokedOnClient...  If it works.
        switch (command) {
        case "RELOADFILTERS":
            self.loadFilterSet(client);
        case "SHOWFILTERS":
            self.showFilters(client);
        default:
            return;
        }
    }
    
}