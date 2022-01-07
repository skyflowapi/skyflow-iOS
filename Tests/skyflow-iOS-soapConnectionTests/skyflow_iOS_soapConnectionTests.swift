import XCTest
@testable import Skyflow

// swiftlint:disable:next type_body_length
final class skyflow_iOS_soapConnectionTests: XCTestCase {
    var skyflow: Client!
    
    override func setUp() {
        self.skyflow = Client(Configuration(tokenProvider: DemoTokenProvider()))
    }
    
    override func tearDown() {
        skyflow = nil
    }
    
    func testEmptyRequestXml() {
        let responseXML = """
            <s:Envelope>
                <s:Header/>
                <s:Body/>
            </s:Envelope>
        """
        
        let requestXML = ""
        
        let config = SoapConnectionConfig(connectionURL: "https://www.skyflow.com", requestXML: requestXML, responseXML: responseXML)
        
        let expectSOAP = XCTestExpectation(description: "Waiting for soap")
        let callback = DemoAPICallback(expectation: expectSOAP)
        
        self.skyflow.invokeSoapConnection(config: config, callback: callback)

        wait(for: [expectSOAP], timeout: 10.0)
        
        let responseData = callback.receivedResponse.utf8
        
        XCTAssertEqual(String(responseData), "Interface: invokeConnection - " + ErrorCodes.EMPTY_REQUEST_XML().description)
    }
    
    func testInvalidRequestXml() {
        let responseXML = """
            <s:Envelope>
                <s:Header/>
                <s:Body/>
            </s:Envelope>
        """
        
        let requestXML = "<"
        
        let config = SoapConnectionConfig(connectionURL: "https://www.skyflow.com", requestXML: requestXML, responseXML: responseXML)
        
        let expectSOAP = XCTestExpectation(description: "Waiting for soap")
        let callback = DemoAPICallback(expectation: expectSOAP)
        
        self.skyflow.invokeSoapConnection(config: config, callback: callback)

        wait(for: [expectSOAP], timeout: 10.0)
        
        let responseData = callback.receivedResponse.utf8
        
        XCTAssertEqual(String(responseData), "Interface: invokeConnection - " + ErrorCodes.INVALID_REQUEST_XML().description)
    }
    
    func testEmptyConnectionUrl() {
        let responseXML = """
            <s:Envelope>
                <s:Header/>
                <s:Body/>
            </s:Envelope>
        """
        
        let requestXML = """
            <s:Envelope>
                <s:Header/>
                <s:Body/>
            </s:Envelope>
        """
        
        let config = SoapConnectionConfig(connectionURL: "", requestXML: requestXML, responseXML: responseXML)
        
        let expectSOAP = XCTestExpectation(description: "Waiting for soap")
        let callback = DemoAPICallback(expectation: expectSOAP)
        
        self.skyflow.invokeSoapConnection(config: config, callback: callback)

        wait(for: [expectSOAP], timeout: 10.0)
        
        let responseData = callback.receivedResponse.utf8
        
        XCTAssertEqual(String(responseData), "Interface: invokeConnection - " + ErrorCodes.EMPTY_CONNECTION_URL().description)
    }
    
    func testInvalidConnectionUrl() {
        let responseXML = """
            <s:Envelope>
                <s:Header/>
                <s:Body/>
            </s:Envelope>
        """
        
        let requestXML = """
            <s:Envelope>
                <s:Header/>
                <s:Body/>
            </s:Envelope>
        """
        
        let config = SoapConnectionConfig(connectionURL: "^", requestXML: requestXML, responseXML: responseXML)
        
        let expectSOAP = XCTestExpectation(description: "Waiting for soap")
        let callback = DemoAPICallback(expectation: expectSOAP)
        
        self.skyflow.invokeSoapConnection(config: config, callback: callback)

        wait(for: [expectSOAP], timeout: 10.0)
        
        let responseData = callback.receivedResponse.utf8
        
        XCTAssertEqual(String(responseData), "Interface: invokeConnection - " + ErrorCodes.INVALID_CONNECTION_URL(value: "^").description)
    }
    
    func testReplaceElementsInXmlInvalidId() {
        var contextOptions = ContextOptions()
        contextOptions.interface = .INVOKE_CONNECTION
        let xml = """
            <s:Envelope>
                <s:Header/>
                <s:Body>
                    <Value>
                        <Skyflow>
                            123
                        </Skyflow>
                    </Value>
                </s:Body>
            </s:Envelope>
        """
        
        do {
            try SoapRequestHelpers.replaceElementsInXML(xml: xml, skyflow: self.skyflow, contextOptions: contextOptions)
            XCTFail()
        }
        catch {
            XCTAssertEqual(error.localizedDescription, "Interface: invokeConnection - Invalid element id 123 present in requestXML")
        }
    }
    
    func testReplaceElementsInXmlUnmountedLabel() {
        var contextOptions = ContextOptions()
        contextOptions.interface = .INVOKE_CONNECTION
        let revealContainer = self.skyflow.container(type: ContainerType.REVEAL)
        let revealElement = revealContainer?.create(input: RevealElementInput(label: "revealElement"))
        let revealElementID = revealElement!.getID()
        let xml = """
            <s:Envelope>
                <s:Header/>
                <s:Body>
                    <Value>
                        <Skyflow>
                            \(revealElementID)
                        </Skyflow>
                    </Value>
                </s:Body>
            </s:Envelope>
        """

        do {
            try SoapRequestHelpers.replaceElementsInXML(xml: xml, skyflow: self.skyflow, contextOptions: contextOptions)
            XCTFail()
        }
        catch {
            XCTAssertEqual(error.localizedDescription, "Interface: invokeConnection - element for revealElement is not mounted")
        }
    }
    
    func testReplaceElementsInXmlUnmountedTextfield() {
        var contextOptions = ContextOptions()
        contextOptions.interface = .INVOKE_CONNECTION
        let collectContainer = self.skyflow.container(type: ContainerType.COLLECT)
        let collectElement = collectContainer?.create(input: CollectElementInput(label: "collectElement", type: .INPUT_FIELD))
        let collectElementID = collectElement!.getID()
        let xml = """
            <s:Envelope>
                <s:Header/>
                <s:Body>
                    <Value>
                        <Skyflow>
                            \(collectElementID)
                        </Skyflow>
                    </Value>
                </s:Body>
            </s:Envelope>
        """

        do {
            try SoapRequestHelpers.replaceElementsInXML(xml: xml, skyflow: self.skyflow, contextOptions: contextOptions)
            XCTFail()
        }
        catch {
            XCTAssertEqual(error.localizedDescription, "Interface: invokeConnection - element for collectElement is not mounted")
        }
    }
    
    func testReplaceElementsInXml() {
        var contextOptions = ContextOptions()
        contextOptions.interface = .INVOKE_CONNECTION
        let revealContainer = self.skyflow.container(type: ContainerType.REVEAL)
        let revealElement = revealContainer?.create(input: RevealElementInput(label: "revealElement"))
        let revealElementID = revealElement!.getID()
        let window = UIWindow()
        window.addSubview(revealElement!)
        revealElement?.actualValue = "123"
        let xml = """
            <s:Envelope>
                <s:Header/>
                <s:Body>
                    <Value>
                        <Skyflow>
                            \(revealElementID)
                        </Skyflow>
                    </Value>
                </s:Body>
            </s:Envelope>
        """

        do {
            let replacedRequestXML = try SoapRequestHelpers.replaceElementsInXML(xml: xml, skyflow: self.skyflow, contextOptions: contextOptions)
            XCTAssert(replacedRequestXML.contains("123"))
        }
        catch {
            XCTFail()
        }
    }
    
    func testHandleXMLResponse() {
        var contextOptions = ContextOptions()
        contextOptions.interface = .INVOKE_CONNECTION
        let revealContainer = self.skyflow.container(type: ContainerType.REVEAL)
        let revealElement = revealContainer?.create(input: RevealElementInput(label: "revealElement"))
        let revealElementID = revealElement!.getID()
        let window = UIWindow()
        window.addSubview(revealElement!)
        
        let responseXML = """
            <s:Envelope>
                <s:Header/>
                <s:Body>
                    <Value>
                        <Skyflow>
                            \(revealElementID)
                        </Skyflow>
                    </Value>
                </s:Body>
            </s:Envelope>
        """
        
        let actualResponse = """
            <s:Envelope>
                <s:Header/>
                <s:Body>
                    <Value>
                        123
                    </Value>
                </s:Body>
            </s:Envelope>
        """

        do {
            try SoapRequestHelpers.handleXMLResponse(responseXML: responseXML, actualResponse: actualResponse, skyflow: self.skyflow, contextOptions: contextOptions)
            XCTAssertEqual(revealElement?.actualValue, "123")
        }
        catch {
            XCTFail()
        }
    }
    
    func testHandleXMLResponseWithUnmountedLabel() {
        var contextOptions = ContextOptions()
        contextOptions.interface = .INVOKE_CONNECTION
        let revealContainer = self.skyflow.container(type: ContainerType.REVEAL)
        let revealElement = revealContainer?.create(input: RevealElementInput(label: "revealElement"))
        let revealElementID = revealElement!.getID()
        
        let responseXML = """
            <s:Envelope>
                <s:Header/>
                <s:Body>
                    <Value>
                        <Skyflow>
                            \(revealElementID)
                        </Skyflow>
                    </Value>
                </s:Body>
            </s:Envelope>
        """
        
        let actualResponse = """
            <s:Envelope>
                <s:Header/>
                <s:Body>
                    <Value>
                        123
                    </Value>
                </s:Body>
            </s:Envelope>
        """

        do {
            try SoapRequestHelpers.handleXMLResponse(responseXML: responseXML, actualResponse: actualResponse, skyflow: self.skyflow, contextOptions: contextOptions)
            XCTFail()
        }
        catch {
            XCTAssertEqual(error.localizedDescription, "Interface: invokeConnection - element for revealElement is not mounted")
        }
    }
    
    func testHandleXMLResponseWithTextfield() {
        var contextOptions = ContextOptions()
        contextOptions.interface = .INVOKE_CONNECTION
        let collectContainer = self.skyflow.container(type: ContainerType.COLLECT)
        let collectElement = collectContainer?.create(input: CollectElementInput(label: "collectElement", type: .INPUT_FIELD))
        let collectElementID = collectElement!.getID()
        let window = UIWindow()
        window.addSubview(collectElement!)
        
        let responseXML = """
            <s:Envelope>
                <s:Header/>
                <s:Body>
                    <Value>
                        <Skyflow>
                            \(collectElementID)
                        </Skyflow>
                    </Value>
                </s:Body>
            </s:Envelope>
        """
        
        let actualResponse = """
            <s:Envelope>
                <s:Header/>
                <s:Body>
                    <Value>
                        123
                    </Value>
                </s:Body>
            </s:Envelope>
        """

        do {
            try SoapRequestHelpers.handleXMLResponse(responseXML: responseXML, actualResponse: actualResponse, skyflow: self.skyflow, contextOptions: contextOptions)
            XCTAssertEqual(collectElement?.actualValue, "123")
        }
        catch {
            XCTFail()
        }
    }
    
    func testHandleXMLResponseWithUnmountedTextfield() {
        var contextOptions = ContextOptions()
        contextOptions.interface = .INVOKE_CONNECTION
        let collectContainer = self.skyflow.container(type: ContainerType.COLLECT)
        let collectElement = collectContainer?.create(input: CollectElementInput(label: "collectElement", type: .INPUT_FIELD))
        let collectElementID = collectElement!.getID()
        
        let responseXML = """
            <s:Envelope>
                <s:Header/>
                <s:Body>
                    <Value>
                        <Skyflow>
                            \(collectElementID)
                        </Skyflow>
                    </Value>
                </s:Body>
            </s:Envelope>
        """
        
        let actualResponse = """
            <s:Envelope>
                <s:Header/>
                <s:Body>
                    <Value>
                        123
                    </Value>
                </s:Body>
            </s:Envelope>
        """

        do {
            try SoapRequestHelpers.handleXMLResponse(responseXML: responseXML, actualResponse: actualResponse, skyflow: self.skyflow, contextOptions: contextOptions)
            XCTFail()
        }
        catch {
            XCTAssertEqual(error.localizedDescription, "Interface: invokeConnection - element for collectElement is not mounted")
        }
    }

    func testHandleXMLResponseWithArray() {
        var contextOptions = ContextOptions()
        contextOptions.interface = .INVOKE_CONNECTION
        let revealContainer = self.skyflow.container(type: ContainerType.REVEAL)
        let revealElement1 = revealContainer?.create(input: RevealElementInput(label: "revealElement1"))
        let revealElement2 = revealContainer?.create(input: RevealElementInput(label: "revealElement2"))
        let revealElementID1 = revealElement1!.getID()
        let revealElementID2 = revealElement2!.getID()
        
        let window = UIWindow()
        window.addSubview(revealElement1!)
        window.addSubview(revealElement2!)
        
        let responseXML = """
            <s:Envelope>
                <s:Header>
                    <List>
                        <Item>
                            <Name>1</Name>
                            <Value>
                                <Skyflow>
                                    \(revealElementID1)
                                </Skyflow>
                            </Value>
                        </Item>
                        <Item>
                            <Name>2</Name>
                            <Value>
                                <Skyflow>
                                    \(revealElementID2)
                                </Skyflow>
                            </Value>
                        </Item>
                    </List>
                </s:Header>
            </s:Envelope>
        """
        
        let actualResponse = """
            <s:Envelope>
                <s:Header>
                    <List>
                        <Item>
                            <Name>1</Name>
                            <Value>123</Value>
                        </Item>
                        <Item>
                            <Name>2</Name>
                            <Value>456</Value>
                        </Item>
                    </List>
                </s:Header>
                <s:Body/>
            </s:Envelope>
        """

        do {
            try SoapRequestHelpers.handleXMLResponse(responseXML: responseXML, actualResponse: actualResponse, skyflow: self.skyflow, contextOptions: contextOptions)
            XCTAssertEqual(revealElement1?.actualValue, "123")
            XCTAssertEqual(revealElement2?.actualValue, "456")
        }
        catch {
            XCTFail()
        }
    }
    
    func testHandleXMLResponseWithAmbiguousElement() {
        var contextOptions = ContextOptions()
        contextOptions.interface = .INVOKE_CONNECTION
        let revealContainer = self.skyflow.container(type: ContainerType.REVEAL)
        let revealElement1 = revealContainer?.create(input: RevealElementInput(label: "revealElement1"))
        let revealElementID1 = revealElement1!.getID()
        
        let window = UIWindow()
        window.addSubview(revealElement1!)
        
        let responseXML = """
            <s:Envelope>
                <s:Header>
                    <List>
                        <Item>
                            <Name>1</Name>
                            <Value>
                                <Skyflow>
                                    \(revealElementID1)
                                </Skyflow>
                            </Value>
                        </Item>
                    </List>
                </s:Header>
            </s:Envelope>
        """
        
        let actualResponse = """
            <s:Envelope>
                <s:Header>
                    <List>
                        <Item>
                            <Name>1</Name>
                            <Value>123</Value>
                        </Item>
                        <Item>
                            <Name>1</Name>
                            <Value>456</Value>
                        </Item>
                    </List>
                </s:Header>
                <s:Body/>
            </s:Envelope>
        """

        do {
            try SoapRequestHelpers.handleXMLResponse(responseXML: responseXML, actualResponse: actualResponse, skyflow: self.skyflow, contextOptions: contextOptions)
            XCTFail()

        }
        catch {
            XCTAssertEqual(error.localizedDescription, "Interface: invokeConnection - " + ErrorCodes.AMBIGUOUS_ELEMENT_FOUND_IN_RESPONSE_XML().description)
        }
    }
    
    func testHandleXMLResponseWithNested() {
        var contextOptions = ContextOptions()
        contextOptions.interface = .INVOKE_CONNECTION
        let revealContainer = self.skyflow.container(type: ContainerType.REVEAL)
        let revealElement1 = revealContainer?.create(input: RevealElementInput(label: "revealElement1"))
        let revealElement2 = revealContainer?.create(input: RevealElementInput(label: "revealElement2"))
        let revealElementID1 = revealElement1!.getID()
        let revealElementID2 = revealElement2!.getID()
        
        let window = UIWindow()
        window.addSubview(revealElement1!)
        window.addSubview(revealElement2!)
        
        let responseXML = """
            <s:Envelope>
                <s:Header>
                    <Header>
                    <List>
                        <Item>
                            <Name>1</Name>
                            <Value>
                                <SubValue>
                                    <Skyflow>
                                        \(revealElementID1)
                                    </Skyflow>
                                </SubValue>
                            </Value>
                        </Item>
                        <Item>
                            <Name>2</Name>
                            <Value>
                                <Skyflow>
                                    \(revealElementID2)
                                </Skyflow>
                            </Value>
                        </Item>
                    </List>
                    </Header>
                </s:Header>
            </s:Envelope>
        """
        
        let actualResponse = """
            <s:Envelope>
                <s:Header>
                    <Header>
                    <List>
                        <Item>
                            <Name>1</Name>
                            <Value>
                                <SubValue> 123 </SubValue>
                            </Value>
                        </Item>
                        <Item>
                            <Name>2</Name>
                            <Value>456</Value>
                        </Item>
                    </List>
                    </Header>
                </s:Header>
                <s:Body/>
            </s:Envelope>
        """

        do {
            try SoapRequestHelpers.handleXMLResponse(responseXML: responseXML, actualResponse: actualResponse, skyflow: self.skyflow, contextOptions: contextOptions)
            XCTAssertEqual(revealElement1?.actualValue, "123")
            XCTAssertEqual(revealElement2?.actualValue, "456")
        }
        catch {
            XCTFail()
        }
    }
    
    func testHandleXMLResponseWithInvalidResponseXml() {
        var contextOptions = ContextOptions()
        contextOptions.interface = .INVOKE_CONNECTION
        
        let responseXML = "<"
        
        let actualResponse = """
            <s:Envelope>
                <s:Header/>
                <s:Body>
                    <Value>
                        123
                    </Value>
                </s:Body>
            </s:Envelope>
        """

        do {
            try SoapRequestHelpers.handleXMLResponse(responseXML: responseXML, actualResponse: actualResponse, skyflow: self.skyflow, contextOptions: contextOptions)
            XCTFail()
        }
        catch {
            XCTAssertEqual(error.localizedDescription, "Interface: invokeConnection - " + ErrorCodes.INVALID_RESPONSE_XML().description)
        }
    }
    
    func testHandleXMLResponseWithInvalidActualResponseXml() {
        var contextOptions = ContextOptions()
        contextOptions.interface = .INVOKE_CONNECTION
        
        let responseXML = """
            <s:Envelope>
                <s:Header/>
                <s:Body>
                    <Value>
                        <Skyflow>
                            123
                        </Skyflow>
                    </Value>
                </s:Body>
            </s:Envelope>
        """

        let actualResponse = "<"
        
        do {
            try SoapRequestHelpers.handleXMLResponse(responseXML: responseXML, actualResponse: actualResponse, skyflow: self.skyflow, contextOptions: contextOptions)
            XCTFail()
        }
        catch {
            XCTAssertEqual(error.localizedDescription, "Interface: invokeConnection - " + ErrorCodes.INVALID_ACTUAL_RESPONSE_XML().description)
        }
    }
    
    func testHandleXMLResponseWithEmptyResponseXml() {
        var contextOptions = ContextOptions()
        contextOptions.interface = .INVOKE_CONNECTION
        
        let responseXML = ""

        let actualResponse = """
            <s:Envelope>
                <s:Header/>
                <s:Body>
                    <Value>
                        123
                    </Value>
                </s:Body>
            </s:Envelope>
        """
        
        do {
            let changedResponseXML = try SoapRequestHelpers.handleXMLResponse(responseXML: responseXML, actualResponse: actualResponse, skyflow: self.skyflow, contextOptions: contextOptions)
            XCTAssertEqual(changedResponseXML, actualResponse)
        }
        catch {
            XCTFail()
        }
    }
    
    func testHandleXMLResponseWithInvalidPathInResponseXml() {
        var contextOptions = ContextOptions()
        contextOptions.interface = .INVOKE_CONNECTION
        
        let responseXML = """
            <s:Envelope>
                <s:Body>
                    <Value>
                        <Skyflow>
                            123
                        </Skyflow>
                    </Value>
                </s:Body>
            </s:Envelope>
        """

        let actualResponse = """
            <s:Envelope>
                <s:Header/>
                <s:Body>
                    <Value1>
                        123
                    </Value1>
                </s:Body>
            </s:Envelope>
        """
        
        do {
            let changedResponseXML = try SoapRequestHelpers.handleXMLResponse(responseXML: responseXML, actualResponse: actualResponse, skyflow: self.skyflow, contextOptions: contextOptions)
            XCTFail()
        }
        catch {
            XCTAssertEqual(error.localizedDescription, "Interface: invokeConnection - " + ErrorCodes.INVALID_PATH_IN_SOAP_CONNECTION(value: "s:Envelope.s:Body").description)
        }
    }
    
    func testHandleXMLResponseWithInvalidIdentifiersInResponseXml() {
        var contextOptions = ContextOptions()
        contextOptions.interface = .INVOKE_CONNECTION
        
        let responseXML = """
            <s:Envelope>
                <s:Body>
                    <Name>1</Name>
                    <Value>
                        <Skyflow>
                            123
                        </Skyflow>
                    </Value>
                </s:Body>
            </s:Envelope>
        """

        let actualResponse = """
            <s:Envelope>
                <s:Header/>
                <s:Body>
                    <Name>2</Name>
                    <Value>
                        123
                    </Value>
                </s:Body>
            </s:Envelope>
        """
        
        do {
            let changedResponseXML = try SoapRequestHelpers.handleXMLResponse(responseXML: responseXML, actualResponse: actualResponse, skyflow: self.skyflow, contextOptions: contextOptions)
            XCTFail()
        }
        catch {
            XCTAssertEqual(error.localizedDescription, "Interface: invokeConnection - " + ErrorCodes.INVALID_IDENTIFIERS_IN_SOAP_CONNECTION(value: "s:Envelope.s:Body").description)
        }
    }


}
