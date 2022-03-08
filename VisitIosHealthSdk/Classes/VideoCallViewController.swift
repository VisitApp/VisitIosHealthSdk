//
//  VideoCallView.swift
//  VisitIOSSdk
//
//  Created by Aditya Raisinghani on 21/07/21.
//

import AVFoundation
import TwilioVideo
import UIKit

@objc(VideoCallViewController)
@available(iOS 11.0, *)
public class VideoCallViewController : UIViewController {
    // MARK:- View Controller Members


    // Video SDK components
    var room: Room?
    var camera: CameraSource?
    var localAudioTrack: LocalAudioTrack!
    var localVideoTrack: LocalVideoTrack!
    var remoteParticipant: RemoteParticipant?
    var remoteView: VideoView?
    var previewModeHeightConstraint: NSLayoutConstraint?
    var previewModeWidthConstraint: NSLayoutConstraint?
    var previewFullScreenHeightConstraint: NSLayoutConstraint?
    var previewFullScreenWidthConstraint: NSLayoutConstraint?

    @IBOutlet weak var videoControlContainer: UIView!
    @IBOutlet weak var backButtonContainer: UIView!
    @IBOutlet weak var previewView: VideoView!
    @IBOutlet weak var remoteViewContainer: VideoView!
    @IBOutlet weak var previewViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var previewViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var previewViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var previewViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var doctorImageView: UIImageView!
    @IBOutlet weak var doctorName: UILabel!
    @IBOutlet weak var toggleVideoImageView: UIButton!
    @IBOutlet weak var toggleAudioImageView: UIButton!
    
    
    deinit {
        // We are done with camera
        if let camera = self.camera {
            camera.stopCapture()
            self.camera = nil
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        if PlatformUtils.isSimulator {
            self.previewView.removeFromSuperview()
        } else {
            // Preview our local camera track in the local video preview view.
            self.startPreview()
        }
        customInit()
    }
    
    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    func customInit() {
        videoControlContainer.layer.cornerRadius = 12;
        videoControlContainer.layer.masksToBounds = true;
        backButtonContainer.layer.cornerRadius = 12;
        backButtonContainer.layer.masksToBounds = true;
    }
    
    func updateLayoutToPreviewView() {
        // Updating constraints for previewView
        DispatchQueue.main.async {
            UIView.animate(withDuration: Double(0.7)) {
                self.previewViewTrailingConstraint.constant = 20
                self.previewViewTopConstraint.constant = 55
                self.previewModeWidthConstraint?.isActive = false
                self.previewModeHeightConstraint?.isActive = false;
                if self.previewFullScreenWidthConstraint != nil {
                    self.previewFullScreenWidthConstraint?.isActive = true;
                } else {
                    self.previewFullScreenWidthConstraint = NSLayoutConstraint(item: self.view, attribute: .width, relatedBy: .equal, toItem: self.previewView!, attribute: .width, multiplier: 1, constant: 0)
                    self.view.addConstraint(self.previewFullScreenWidthConstraint!)
                }
                if self.previewFullScreenHeightConstraint != nil {
                    self.previewFullScreenHeightConstraint?.isActive = true
                } else {
                    self.previewFullScreenHeightConstraint = NSLayoutConstraint(item: self.view, attribute: .height, relatedBy: .equal, toItem: self.previewView!, attribute: .height, multiplier: 1, constant: 0)
                    self.view.addConstraint(self.previewFullScreenHeightConstraint!)
                }
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func setupRemoteVideoView() {
        // Creating `VideoView` programmatically
        self.remoteView = VideoView(frame: CGRect.zero, delegate: self)

        self.view.insertSubview(self.remoteView!, at: 0)
        
        print("Setting up remote view")
        
        // Updating constraints for previewView
        DispatchQueue.main.async {
            UIView.animate(withDuration: Double(0.7)) {
                self.previewViewTrailingConstraint.constant = 20
                self.previewViewTopConstraint.constant = 55
                self.previewViewHeightConstraint?.isActive = false
                self.previewViewWidthConstraint?.isActive = false
                self.previewFullScreenHeightConstraint?.isActive = false
                self.previewFullScreenWidthConstraint?.isActive = false
                if self.previewModeWidthConstraint != nil {
                    self.previewModeWidthConstraint?.isActive = true;
                } else {
                    self.previewModeWidthConstraint = NSLayoutConstraint(item: self.previewView!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 77)
                    self.previewView.addConstraint(self.previewModeWidthConstraint!)
                }
                if self.previewModeHeightConstraint != nil {
                    self.previewModeHeightConstraint?.isActive = true
                } else {
                    self.previewModeHeightConstraint = NSLayoutConstraint(item: self.previewView!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 110)
                    self.previewView.addConstraint(self.previewModeHeightConstraint!)
                }
                self.view.layoutIfNeeded()
            }
        }
        
        // `VideoView` supports scaleToFill, scaleAspectFill and scaleAspectFit
        // scaleAspectFit is the default mode when you create `VideoView` programmatically.
        self.remoteView!.contentMode = .scaleAspectFit;

        let centerX = NSLayoutConstraint(item: self.remoteView!,
                                         attribute: NSLayoutConstraint.Attribute.centerX,
                                         relatedBy: NSLayoutConstraint.Relation.equal,
                                         toItem: self.view,
                                         attribute: NSLayoutConstraint.Attribute.centerX,
                                         multiplier: 1,
                                         constant: 0);
        self.view.addConstraint(centerX)
        let centerY = NSLayoutConstraint(item: self.remoteView!,
                                         attribute: NSLayoutConstraint.Attribute.centerY,
                                         relatedBy: NSLayoutConstraint.Relation.equal,
                                         toItem: self.view,
                                         attribute: NSLayoutConstraint.Attribute.centerY,
                                         multiplier: 1,
                                         constant: 0);
        self.view.addConstraint(centerY)
        let width = NSLayoutConstraint(item: self.remoteView!,
                                       attribute: NSLayoutConstraint.Attribute.width,
                                       relatedBy: NSLayoutConstraint.Relation.equal,
                                       toItem: self.view,
                                       attribute: NSLayoutConstraint.Attribute.width,
                                       multiplier: 1,
                                       constant: 0);
        self.view.addConstraint(width)
        let height = NSLayoutConstraint(item: self.remoteView!,
                                        attribute: NSLayoutConstraint.Attribute.height,
                                        relatedBy: NSLayoutConstraint.Relation.equal,
                                        toItem: self.view,
                                        attribute: NSLayoutConstraint.Attribute.height,
                                        multiplier: 1,
                                        constant: 0);
        self.view.addConstraint(height)
        
        
    }

    @IBAction func disconnect(_ sender: Any) {
        self.room?.disconnect()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func toggleMic(_ sender: Any) {
        let podBundle = Bundle(for: VideoCallViewController.self)
        if (self.localAudioTrack != nil) {
            self.localAudioTrack?.isEnabled = !(self.localAudioTrack?.isEnabled)!
            
            // Update the button title
            if (self.localAudioTrack?.isEnabled == true) {
                let muteIcon = UIImage(named: "Mic_On.png", in: podBundle, compatibleWith: nil)
//                let muteIcon = UIImage(named: "mute.png")
                self.toggleAudioImageView.setImage(muteIcon, for: .normal)
            } else {
                let muteIcon = UIImage(named: "mute.png", in: podBundle, compatibleWith: nil)
//                let muteIcon = UIImage(named: "Mic_On.png")
                self.toggleAudioImageView.setImage(muteIcon, for: .normal)
            }
        }
    }
    
    @IBAction func toggleVideo(_ sender: Any) {
        let podBundle = Bundle(for: VideoCallViewController.self)
        if (self.localVideoTrack != nil) {
            self.localVideoTrack?.isEnabled = !(self.localVideoTrack?.isEnabled)!
            if (self.localVideoTrack?.isEnabled == true) {
                let videoIcon = UIImage(named: "Camera_On.png", in: podBundle, compatibleWith: nil)
//                let videoIcon = UIImage(named: "video-off.png")
                self.toggleVideoImageView.setImage(videoIcon, for: .normal)
//                self.toggleVideoImageView.imageView?.image = videoIcon;
            } else {
                let videoIcon = UIImage(named: "video-off.png", in: podBundle, compatibleWith: nil)
//                let videoIcon = UIImage(named: "Camera_On.png")
                self.toggleVideoImageView.setImage(videoIcon, for: .normal)
//                self.toggleVideoImageView.imageView?.image = videoIcon;
            }
        }
    }
    
    @IBAction func flipCamera(_ sender: Any) {
        var newDevice: AVCaptureDevice?

        if let camera = self.camera, let captureDevice = camera.device {
            if captureDevice.position == .front {
                newDevice = CameraSource.captureDevice(position: .back)
            } else {
                newDevice = CameraSource.captureDevice(position: .front)
            }

            if let newDevice = newDevice {
                camera.selectCaptureDevice(newDevice) { (captureDevice, videoFormat, error) in
                    if let error = error {
                        self.logMessage(messageText: "Error selecting capture device.\ncode = \((error as NSError).code) error = \(error.localizedDescription)")
                    } else {
                        self.previewView.shouldMirror = (captureDevice.position == .front)
                    }
                }
            }
        }
    }
    
    func logMessage(messageText: String) {
        NSLog(messageText)
    }
    
    // MARK:- Private
    func startPreview() {
        if PlatformUtils.isSimulator {
            return
        }

        let frontCamera = CameraSource.captureDevice(position: .front)
        let backCamera = CameraSource.captureDevice(position: .back)

        if (frontCamera != nil || backCamera != nil) {

            let options = CameraSourceOptions { (builder) in
                if #available(iOS 13.0, *) {
                    // Track UIWindowScene events for the key window's scene.
                    // The example app disables multi-window support in the .plist (see UIApplicationSceneManifestKey).
                    builder.orientationTracker = UserInterfaceTracker(scene: UIApplication.shared.keyWindow!.windowScene!)
                }
            }
            // Preview our local camera track in the local video preview view.
            camera = CameraSource(options: options, delegate: self)
            localVideoTrack = LocalVideoTrack(source: camera!, enabled: true, name: "Camera")

            // Add renderer to video track for local preview
            localVideoTrack!.addRenderer(self.previewView)
            logMessage(messageText: "Video track created")


            camera!.startCapture(device: frontCamera != nil ? frontCamera! : backCamera!) { (captureDevice, videoFormat, error) in
                if let error = error {
                    self.logMessage(messageText: "Capture failed with error.\ncode = \((error as NSError).code) error = \(error.localizedDescription)")
                } else {
                    self.previewView.shouldMirror = (captureDevice.position == .front)
                }
            }
        }
        else {
            self.logMessage(messageText:"No front or back capture device found!")
        }
    }
    
    @objc func flipCamera() {
        var newDevice: AVCaptureDevice?

        if let camera = self.camera, let captureDevice = camera.device {
            if captureDevice.position == .front {
                newDevice = CameraSource.captureDevice(position: .back)
            } else {
                newDevice = CameraSource.captureDevice(position: .front)
            }

            if let newDevice = newDevice {
                camera.selectCaptureDevice(newDevice) { (captureDevice, videoFormat, error) in
                    if let error = error {
                        self.logMessage(messageText: "Error selecting capture device.\ncode = \((error as NSError).code) error = \(error.localizedDescription)")
                    } else {
                        self.previewView.shouldMirror = (captureDevice.position == .front)
                    }
                }
            }
        }
    }
    
    func prepareLocalMedia() {
        // We will share local audio and video when we connect to the Room.

        // Create an audio track.
        if (localAudioTrack == nil) {
            localAudioTrack = LocalAudioTrack(options: nil, enabled: true, name: "Microphone")

            if (localAudioTrack == nil) {
                logMessage(messageText: "Failed to create audio track")
            }
        }

        // Create a video track which captures from the camera.
        if (localVideoTrack == nil) {
            self.startPreview()
        }
    }
    
    func setDoctorDetails(doctorName: String, doctorProfileImg: String) {
        self.doctorName.text = doctorName
        let url = URL(string: doctorProfileImg)

        DispatchQueue.global().async {
            let data = try? Data(contentsOf: url!)
            DispatchQueue.main.async {
                self.doctorImageView.image = UIImage(data: data!)
            }
        }
    }
    
    @objc public func connect(accessToken: String, roomName: String, doctorName: String, doctorProfileImg: String) {

        self.prepareLocalMedia()
        self.setDoctorDetails(doctorName: doctorName, doctorProfileImg: doctorProfileImg)
        // Preparing the connect options with the access token that we fetched
        let connectOptions = ConnectOptions(token: accessToken) { (builder) in

            // Use the local media that we prepared earlier.
            builder.audioTracks = self.localAudioTrack != nil ? [self.localAudioTrack!] : [LocalAudioTrack]()
            builder.videoTracks = self.localVideoTrack != nil ? [self.localVideoTrack!] : [LocalVideoTrack]()
            
            // Use the preferred audio codec
            if let preferredAudioCodec = Settings.shared.audioCodec {
                builder.preferredAudioCodecs = [preferredAudioCodec]
            }
            
            // Use the preferred video codec
            if let preferredVideoCodec = Settings.shared.videoCodec {
                builder.preferredVideoCodecs = [preferredVideoCodec]
            }
            
            // Use the preferred encoding parameters
            if let encodingParameters = Settings.shared.getEncodingParameters() {
                builder.encodingParameters = encodingParameters
            }

            // Use the preferred signaling region
            if let signalingRegion = Settings.shared.signalingRegion {
                builder.region = signalingRegion
            }

            // The name of the Room where the Client will attempt to connect to. Please note that if you pass an empty
            // Room `name`, the Client will create one for you. You can get the name or sid from any connected Room.
            builder.roomName = roomName
        }

        // Connect to the Room using the options we provided.
        room = TwilioVideoSDK.connect(options: connectOptions, delegate: self)

        logMessage(messageText: "Connecting to \(roomName )")

//        self.showRoomUI(inRoom: true)
//        self.dismissKeyboard()
    }
    
    
    func renderRemoteParticipant(participant : RemoteParticipant) -> Bool {
        // This example renders the first subscribed RemoteVideoTrack from the RemoteParticipant.
        let videoPublications = participant.remoteVideoTracks
        for publication in videoPublications {
            if let subscribedVideoTrack = publication.remoteTrack,
                publication.isTrackSubscribed {
                setupRemoteVideoView()
                subscribedVideoTrack.addRenderer(self.remoteView!)
                self.remoteParticipant = participant
                return true
            }
        }
        return false
    }

    func renderRemoteParticipants(participants : Array<RemoteParticipant>) {
        for participant in participants {
            // Find the first renderable track.
            if participant.remoteVideoTracks.count > 0,
                renderRemoteParticipant(participant: participant) {
                break
            }
        }
    }

    func cleanupRemoteParticipant() {
        if self.remoteParticipant != nil {
            self.remoteView?.removeFromSuperview()
            self.remoteView = nil
            self.remoteParticipant = nil
        }
    }
    
}

// MARK:- RoomDelegate
@available(iOS 11.0, *)
extension VideoCallViewController : RoomDelegate {
    public func roomDidConnect(room: Room) {
        logMessage(messageText: "Connected to room \(room.name) as \(room.localParticipant?.identity ?? "")")

        // This example only renders 1 RemoteVideoTrack at a time. Listen for all events to decide which track to render.
        for remoteParticipant in room.remoteParticipants {
            remoteParticipant.delegate = self
        }
    }

    public func roomDidDisconnect(room: Room, error: Error?) {
        logMessage(messageText: "Disconnected from room \(room.name), error = \(String(describing: error))")
        
        self.cleanupRemoteParticipant()
        self.room = nil
        
//        self.showRoomUI(inRoom: false)
    }

    public func roomDidFailToConnect(room: Room, error: Error) {
        logMessage(messageText: "Failed to connect to room with error = \(String(describing: error))")
        self.room = nil
        
//        self.showRoomUI(inRoom: false)
    }

    public func roomIsReconnecting(room: Room, error: Error) {
        logMessage(messageText: "Reconnecting to room \(room.name), error = \(String(describing: error))")
    }

    public func roomDidReconnect(room: Room) {
        logMessage(messageText: "Reconnected to room \(room.name)")
    }

    public func participantDidConnect(room: Room, participant: RemoteParticipant) {
        // Listen for events from all Participants to decide which RemoteVideoTrack to render.
        participant.delegate = self

        logMessage(messageText: "Participant \(participant.identity) connected with \(participant.remoteAudioTracks.count) audio and \(participant.remoteVideoTracks.count) video tracks")
    }

    public func participantDidDisconnect(room: Room, participant: RemoteParticipant) {
        logMessage(messageText: "Room \(room.name), Participant \(participant.identity) disconnected")
        
        updateLayoutToPreviewView()

        // Nothing to do in this example. Subscription events are used to add/remove renderers.
    }
}

// MARK:- RemoteParticipantDelegate
@available(iOS 11.0, *)
extension VideoCallViewController : RemoteParticipantDelegate {

    public func remoteParticipantDidPublishVideoTrack(participant: RemoteParticipant, publication: RemoteVideoTrackPublication) {
        // Remote Participant has offered to share the video Track.
        
        logMessage(messageText: "Participant \(participant.identity) published \(publication.trackName) video track")
    }

    public func remoteParticipantDidUnpublishVideoTrack(participant: RemoteParticipant, publication: RemoteVideoTrackPublication) {
        // Remote Participant has stopped sharing the video Track.

        logMessage(messageText: "Participant \(participant.identity) unpublished \(publication.trackName) video track")
    }

    public func remoteParticipantDidPublishAudioTrack(participant: RemoteParticipant, publication: RemoteAudioTrackPublication) {
        // Remote Participant has offered to share the audio Track.

        logMessage(messageText: "Participant \(participant.identity) published \(publication.trackName) audio track")
    }

    public func remoteParticipantDidUnpublishAudioTrack(participant: RemoteParticipant, publication: RemoteAudioTrackPublication) {
        // Remote Participant has stopped sharing the audio Track.

        logMessage(messageText: "Participant \(participant.identity) unpublished \(publication.trackName) audio track")
    }

    public func didSubscribeToVideoTrack(videoTrack: RemoteVideoTrack, publication: RemoteVideoTrackPublication, participant: RemoteParticipant) {
        // The LocalParticipant is subscribed to the RemoteParticipant's video Track. Frames will begin to arrive now.

        logMessage(messageText: "Subscribed to \(publication.trackName) video track for Participant \(participant.identity)")

        if (self.remoteParticipant == nil) {
            _ = renderRemoteParticipant(participant: participant)
        }
    }
    
    public func didUnsubscribeFromVideoTrack(videoTrack: RemoteVideoTrack, publication: RemoteVideoTrackPublication, participant: RemoteParticipant) {
        // We are unsubscribed from the remote Participant's video Track. We will no longer receive the
        // remote Participant's video.
        
        logMessage(messageText: "Unsubscribed from \(publication.trackName) video track for Participant \(participant.identity)")

        if self.remoteParticipant == participant {
            cleanupRemoteParticipant()

            // Find another Participant video to render, if possible.
            if var remainingParticipants = room?.remoteParticipants,
                let index = remainingParticipants.firstIndex(of: participant) {
                remainingParticipants.remove(at: index)
                renderRemoteParticipants(participants: remainingParticipants)
            }
        }
    }

    public func didSubscribeToAudioTrack(audioTrack: RemoteAudioTrack, publication: RemoteAudioTrackPublication, participant: RemoteParticipant) {
        // We are subscribed to the remote Participant's audio Track. We will start receiving the
        // remote Participant's audio now.
       
        logMessage(messageText: "Subscribed to \(publication.trackName) audio track for Participant \(participant.identity)")
    }
    
    public func didUnsubscribeFromAudioTrack(audioTrack: RemoteAudioTrack, publication: RemoteAudioTrackPublication, participant: RemoteParticipant) {
        // We are unsubscribed from the remote Participant's audio Track. We will no longer receive the
        // remote Participant's audio.
        
        logMessage(messageText: "Unsubscribed from \(publication.trackName) audio track for Participant \(participant.identity)")
    }

    public func remoteParticipantDidEnableVideoTrack(participant: RemoteParticipant, publication: RemoteVideoTrackPublication) {
        logMessage(messageText: "Participant \(participant.identity) enabled \(publication.trackName) video track")
    }

    public func remoteParticipantDidDisableVideoTrack(participant: RemoteParticipant, publication: RemoteVideoTrackPublication) {
        logMessage(messageText: "Participant \(participant.identity) disabled \(publication.trackName) video track")
    }

    public func remoteParticipantDidEnableAudioTrack(participant: RemoteParticipant, publication: RemoteAudioTrackPublication) {
        logMessage(messageText: "Participant \(participant.identity) enabled \(publication.trackName) audio track")
    }

    public func remoteParticipantDidDisableAudioTrack(participant: RemoteParticipant, publication: RemoteAudioTrackPublication) {
        logMessage(messageText: "Participant \(participant.identity) disabled \(publication.trackName) audio track")
    }

    public func didFailToSubscribeToAudioTrack(publication: RemoteAudioTrackPublication, error: Error, participant: RemoteParticipant) {
        logMessage(messageText: "FailedToSubscribe \(publication.trackName) audio track, error = \(String(describing: error))")
    }

    public func didFailToSubscribeToVideoTrack(publication: RemoteVideoTrackPublication, error: Error, participant: RemoteParticipant) {
        logMessage(messageText: "FailedToSubscribe \(publication.trackName) video track, error = \(String(describing: error))")
    }
}

// MARK:- VideoViewDelegate
@available(iOS 11.0, *)
extension VideoCallViewController : VideoViewDelegate {
    public func videoViewDimensionsDidChange(view: VideoView, dimensions: CMVideoDimensions) {
        self.view.setNeedsLayout()
    }
}

// MARK:- CameraSourceDelegate
extension VideoCallViewController : CameraSourceDelegate {
    public func cameraSourceDidFail(source: CameraSource, error: Error) {
        logMessage(messageText: "Camera source failed with error: \(error.localizedDescription)")
        source.previewView?.removeFromSuperview()
    }
}
