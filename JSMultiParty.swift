//  MultiParty
//  Created by Jordan Sitkin on 2/25/15
//  Copyright © 2015 Jordan Sitkin. All rights reserved.

import Foundation
import MultipeerConnectivity

public protocol JSMultiPartyDelegate {
  func didReceiveMessageFromPeerId(peerId: MCPeerID, message: AnyObject)
  func didConnectToPeerId(peerId: MCPeerID)
  func didDisconnectFromPeerId(peerId: MCPeerID)
  func didFindPeerId(peerId: MCPeerID, name: String?)
  func didLosePeerId(peerId: MCPeerID)
  func didStartReceivingImage(peerId: MCPeerID, progress: NSProgress)
  func didFinishReceivingImage(peerId: MCPeerID, image: UIImage)
  func didReceiveStream(stream: NSInputStream, withName: String, fromPeer: MCPeerID)
  func didFailToReceiveImage(peerId: MCPeerID, error: NSError)
  func didNotStartAdvertisingPeer(error: NSError)
  func didNotStartBrowsingForPeers(error: NSError)
}

public class JSMultiParty: NSObject,
MCSessionDelegate,
MCNearbyServiceAdvertiserDelegate,
MCNearbyServiceBrowserDelegate {
  
  public var delegate: JSMultiPartyDelegate?
  public var myPeerId: MCPeerID! = nil
  var serviceType: String! = nil
  var mcSession: MCSession! = nil
  var serviceAdvertiser: MCNearbyServiceAdvertiser! = nil
  var serviceBrowser: MCNearbyServiceBrowser! = nil
  
  let recycledPeerIdKey = "recycled-multiparty-peer-id"
  
  public init(serviceType: String) {
    super.init()
    self.myPeerId = getRecycledPeerId()
    self.serviceType = serviceType
  }
  
  deinit {
    self.disconnect()
  }
  
  public func connectAs(name: String) {
    if mcSession == nil {
      mcSession = MCSession(peer: myPeerId)
      mcSession.delegate = self
    }
    if serviceAdvertiser == nil {
      let dict = ["Name": name]
      serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: dict, serviceType: serviceType)
      serviceAdvertiser.delegate = self
      serviceAdvertiser.startAdvertisingPeer()
    }
    if serviceBrowser == nil {
      serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
      serviceBrowser.delegate = self
      serviceBrowser.startBrowsingForPeers()
    }
  }
  
  public func disconnect() {
    self.serviceAdvertiser.stopAdvertisingPeer()
    self.serviceAdvertiser.delegate = nil
    self.serviceAdvertiser = nil
    self.serviceBrowser.stopBrowsingForPeers()
    self.serviceBrowser.delegate = nil
    self.serviceBrowser = nil
    self.mcSession.disconnect()
    self.mcSession.delegate = nil
    self.mcSession = nil
  }
  
  public func connectedPeers() -> [MCPeerID] {
    return self.mcSession.connectedPeers as [MCPeerID]
  }
  
  public func sendMessageToPeerId(peerId: MCPeerID, message: AnyObject) -> NSError? {
    let data: NSData = NSKeyedArchiver.archivedDataWithRootObject(message)
    var error: NSError?
    self.mcSession.sendData(data, toPeers: [peerId], withMode: MCSessionSendDataMode.Reliable, error: &error)
    return error
  }
  
  public func sendImageToPeerId(peerId: MCPeerID, imageURL: NSURL, imageName: String) {
    self.mcSession.sendResourceAtURL(imageURL, withName: imageName, toPeer: peerId, withCompletionHandler: nil)
  }
  
  // mark: MCSessionDelegate
  
  public func session(
    session: MCSession!,
    didReceiveData data: NSData!,
    fromPeer peerId: MCPeerID!
  ) {
    let received: AnyObject? = NSKeyedUnarchiver.unarchiveObjectWithData(data)
    if let message: AnyObject = NSKeyedUnarchiver.unarchiveObjectWithData(data!) {
      self.delegate?.didReceiveMessageFromPeerId(peerId, message: message)
    }
  }
  
  public func session(
    session: MCSession!,
    peer peerId: MCPeerID!,
    didChangeState state: MCSessionState
  ) {
    if state == MCSessionState.Connected {
      delegate?.didConnectToPeerId(peerId)
    } else if state == MCSessionState.NotConnected {
      delegate?.didDisconnectFromPeerId(peerId)
    }
  }
  
  public func session(session: MCSession!, didReceiveStream stream: NSInputStream!,
    withName streamName: String!, fromPeer peerID: MCPeerID!) {
    self.delegate?.didReceiveStream(stream, withName: streamName, fromPeer: peerID)
  }
  
  public func session(session: MCSession!,
    didStartReceivingResourceWithName resourceName: String!,
    fromPeer peerID: MCPeerID!, withProgress progress: NSProgress!) {
    delegate?.didStartReceivingImage(peerID, progress: progress)
  }
  
  public func session(session: MCSession!,
    didFinishReceivingResourceWithName resourceName: String!,
    fromPeer peerID: MCPeerID!,
    atURL localURL: NSURL!, withError error: NSError!) {
    if error != nil {
      delegate?.didFailToReceiveImage(peerID, error: error)
    } else {
      let imageData = NSData(contentsOfURL: localURL)
      let image = UIImage(data: imageData!, scale: 2.0)
      delegate?.didFinishReceivingImage(peerID, image: image!)
    }
  }
  
  // mark: MCNearbyServiceBrowserDelegate
  
  public func advertiser(advertiser: MCNearbyServiceAdvertiser!, didNotStartAdvertisingPeer error: NSError!) {
    self.delegate?.didNotStartAdvertisingPeer(error)
  }
  
  public func advertiser(advertiser: MCNearbyServiceAdvertiser!, didReceiveInvitationFromPeer peerID: MCPeerID!, withContext context: NSData!, invitationHandler: ((Bool, MCSession!) -> Void)!) {
    invitationHandler(true, self.mcSession)
  }
  
  // mark: MCNearbyServiceAdvertiserDelegate
  
  public func browser(browser: MCNearbyServiceBrowser!, didNotStartBrowsingForPeers error: NSError!) {
    self.delegate?.didNotStartBrowsingForPeers(error)
  }
  
  public func browser(browser: MCNearbyServiceBrowser!, foundPeer peerID: MCPeerID!, withDiscoveryInfo info: [NSObject : AnyObject]!) {
    let name = info["Name"] as? String
    delegate?.didFindPeerId(peerID, name: name)
    if self.myPeerId.hash < peerID.hash {
      self.serviceBrowser.invitePeer(peerID, toSession: self.mcSession, withContext: nil, timeout: 10)
    }
  }
  
  public func browser(browser: MCNearbyServiceBrowser!, lostPeer peerID: MCPeerID!) {
    delegate?.didLosePeerId(peerID)
  }
  
  // mark: private parts
  
  private func getRecycledPeerId() -> MCPeerID {
    let defaults = NSUserDefaults.standardUserDefaults()
    if let peerIdData = defaults.objectForKey(recycledPeerIdKey) as? NSData {
      return NSKeyedUnarchiver.unarchiveObjectWithData(peerIdData) as MCPeerID
    } else {
      let peerId = MCPeerID(displayName: UIDevice.currentDevice().name)
      let peerIdData = NSKeyedArchiver.archivedDataWithRootObject(peerId)
      defaults.setObject(peerIdData, forKey: recycledPeerIdKey)
      return peerId
    }
  }
  
}
