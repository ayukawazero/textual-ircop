

class OperFilter: NSObject {                        // object class for base element in XML file after root
    
    var enabled: String = ""
    var expression: String = ""
    var format: String = ""
    var color: String = ""
    
    override init() {
        super.init()
    }
}

// MARK: - SwiftXMLParser

class SwiftXMLParser: NSObject, NSXMLParserDelegate {
    
    var XMLfile: NSInputStream
    var parser: NSXMLParser
    var currentItem: OperFilter?
    var parsedItems: [OperFilter] = []              // final result of parse is stored here
    var currentString: String = ""
    var storingCharacters = false
    var startTime = NSTimeInterval()
    var lastDuration = NSTimeInterval()
    var done = true
    
    subscript(i: Int) -> OperFilter {               // so we can index right into the array of results
        return parsedItems[i]
    }
    
    init(fromFileAtPath path: String!) {            // initialize with path to a valid XML file
        self.XMLfile = NSInputStream(fileAtPath: path)
        self.parser = NSXMLParser(stream: XMLfile)
        super.init()
    }
    
    func getParsedItems() -> [OperFilter] {
        return self.parsedItems
    }
    
    func getLastDuration() -> NSTimeInterval {
        return self.lastDuration
    }
    
    func displayItems() {
        for item in self.parsedItems {
            println("enabled: \(item.enabled)")
            println("expression: \(item.expression)")
            println("format: \(item.format)")
            println("color: \(item.color)")
        }
    }
    
    func start() {               // call after init with an XML file to begin parse
        self.currentItem = nil
        self.parsedItems = []
        self.currentString = ""
        readAndParse()
    }
    
    func readAndParse() {
        parser.delegate = self  // make this object the delegate for the parser object
        done = false
        parser.parse()
    }
    
    func finishedCurrentItem() {
        self.parsedItems.append(currentItem! as OperFilter)  // keep track of parsed filters
    }
    
    // MARK: - NSXMLParserDelegate
    
    func parserDidStartDocument(parser: NSXMLParser!) {
        self.startTime = NSDate.timeIntervalSinceReferenceDate()     // simple timer hack
    }
    
    func parserDidEndDocument(parser: NSXMLParser!) {
        self.done = true
        self.lastDuration = NSDate.timeIntervalSinceReferenceDate() - startTime
    }
    
    func parser(parser: NSXMLParser!, didStartElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!, attributes attributeDict: [NSObject : AnyObject]!) {

        if elementName == "filter" {
            currentItem = OperFilter()
            if let enabled = attributeDict["enabled"] as? NSString {
                if let item = currentItem? {
                    item.enabled = enabled //NSString(enabled! as NSString)           // do I need all this optional unwrapping?
                }
            }
            
        } else if elementName == "format" {
            currentString = ""
            if let color = attributeDict["color"] as? NSString {
                if let item = self.currentItem? {
                    item.color = color
                }
            }
            self.storingCharacters = true
        } else if elementName == "expression" {
            currentString = ""
            storingCharacters = true
        }
        
    }
    
    func parser(parser: NSXMLParser!, didEndElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!) {
        
        if let item = currentItem? {                            // I would like to make an abstract version of this
            if elementName == "filter" {
                finishedCurrentItem()
            } else if elementName == "expression" {
                item.expression = currentString
            } else if elementName == "format" {
                item.format = currentString
            }
            storingCharacters = false
        }

    }
    
    func parser(parser: NSXMLParser!, foundCharacters string: String!) {
        if self.storingCharacters == true {
            self.currentString += string
        }
    }
    
    func parser(parser: NSXMLParser!, parseErrorOccurred parseError: NSError!) {
        // NSLog(parseError.localizedFailureReason)
        //NSLog(parseError.localizedDescription)
        // other error handling (see http://nomothetis.svbtle.com/error-handling-in-swift)
    }
    
}
