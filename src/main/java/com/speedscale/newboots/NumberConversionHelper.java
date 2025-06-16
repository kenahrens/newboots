package com.speedscale.newboots;

import javax.xml.soap.MessageFactory;
import javax.xml.soap.SOAPBody;
import javax.xml.soap.SOAPConnection;
import javax.xml.soap.SOAPConnectionFactory;
import javax.xml.soap.SOAPElement;
import javax.xml.soap.SOAPEnvelope;
import javax.xml.soap.SOAPMessage;
import javax.xml.soap.SOAPPart;
import java.io.ByteArrayOutputStream;

public class NumberConversionHelper {
    private static final String SOAP_ENDPOINT = "https://www.dataaccess.com/webservicesserver/NumberConversion.wso";
    private static final String SOAP_ACTION = "http://www.dataaccess.com/webservicesserver/NumberConversion.wso/NumberToWords";

    public static String numberToWords(int number) throws Exception {
        // Create SOAP Connection
        SOAPConnectionFactory soapConnectionFactory = SOAPConnectionFactory.newInstance();
        SOAPConnection soapConnection = soapConnectionFactory.createConnection();

        // Create SOAP Request
        SOAPMessage soapRequest = createSOAPRequest(number);

        // Send SOAP Message to SOAP Server
        SOAPMessage soapResponse = soapConnection.call(soapRequest, SOAP_ENDPOINT);

        // Process the SOAP Response
        String result = extractWordsFromResponse(soapResponse);
        soapConnection.close();
        return result;
    }

    private static SOAPMessage createSOAPRequest(int number) throws Exception {
        MessageFactory messageFactory = MessageFactory.newInstance();
        SOAPMessage soapMessage = messageFactory.createMessage();
        SOAPPart soapPart = soapMessage.getSOAPPart();

        String serverURI = "http://www.dataaccess.com/webservicesserver/";

        // SOAP Envelope
        SOAPEnvelope envelope = soapPart.getEnvelope();
        envelope.addNamespaceDeclaration("web", serverURI);

        // SOAP Body
        SOAPBody soapBody = envelope.getBody();
        SOAPElement numberToWordsElem = soapBody.addChildElement("NumberToWords", "web");
        SOAPElement ubiNumElem = numberToWordsElem.addChildElement("ubiNum", "web");
        ubiNumElem.addTextNode(Integer.toString(number));

        soapMessage.saveChanges();
        return soapMessage;
    }

    private static String extractWordsFromResponse(SOAPMessage soapResponse) throws Exception {
        // Debug: print the full SOAP response
        java.io.ByteArrayOutputStream out = new java.io.ByteArrayOutputStream();
        soapResponse.writeTo(out);
        System.out.println("SOAP Response: " + out.toString());

        SOAPBody body = soapResponse.getSOAPBody();
        org.w3c.dom.NodeList nodes = ((org.w3c.dom.Element) body).getElementsByTagNameNS(
            "http://www.dataaccess.com/webservicesserver/",
            "NumberToWordsResult"
        );
        if (nodes.getLength() > 0) {
            org.w3c.dom.Node resultNode = nodes.item(0);
            String val = resultNode.getTextContent();
            if (val != null) return val.trim();
        }
        return null;
    }
} 