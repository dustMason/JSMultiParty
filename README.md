# MultiParty

[![Version](https://img.shields.io/cocoapods/v/MultiParty.svg?style=flat)](http://cocoadocs.org/docsets/MultiParty)
[![License](https://img.shields.io/cocoapods/l/MultiParty.svg?style=flat)](http://cocoadocs.org/docsets/MultiParty)
[![Platform](https://img.shields.io/cocoapods/p/MultiParty.svg?style=flat)](http://cocoadocs.org/docsets/MultiParty)

While implementing Apple's MultipeerConnectivity framework in a recent project, I ran up against a few issues with it. Some research revealed that I wasn't alone in my frustations so I whipped up a small class which implements `MCSessionDelegate`, `MCNearbyServiceAdvertiserDelegate` and `MCNearbyServiceBrowserDelegate`. It was originally designed for usage in a chat application but would suit other purposes well.

Why you might want to use it:

- It avoids the issue of "ghost" peers with identical names appearing on the network by storing and re-using an `MCPeerID` for each client. It further alleviates this issue by allowing the apparent name of each client to change by using the `discoveryInfo` property of each `MCNearbyServiceAdvertiser` instance while keeping the `displayName` the same.
- Clients automatically invite one another as soon as they appear on the network. The "mutual invite" issue is avoided by determining the inviter and invitee by comparing hashes of their peer IDs.
- It offers convenience methods for sending / receiving UIImage instances among clients.

## Usage

Import the module:

```
import MultiParty
```

Then implement `JSMultiPartyDelegate`:

```
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
```

## Requirements

Being a new Swift based CocoaPod, it wont work on < iOS 8. For iOS 7+ support you can simply copy the class into your project.

## Installation

MultiParty is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod "MultiParty"

## Author

Jordan Sitkin, jordan@fiftyfootfoghorn.com

## License

MultiParty is available under the MIT license. See the LICENSE file for more info.

