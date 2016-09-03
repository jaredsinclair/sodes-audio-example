//
//  ViewController.swift
//  SodesExample
//
//  Created by Jared Sinclair on 9/2/16.
//
//

import UIKit
import SodesAudio
import MediaPlayer

struct TestSource: PlaybackSource {
    let uniqueId: String = "abcxyz"
    var artistId: String = "123456"
    var remoteUrl: URL = URL(string: "http://content.blubrry.com/exponent/exponent86.mp3")!
    var title: String? = "Track Title"
    var albumTitle: String? = "Album Title"
    var artist: String? = "Artist"
    var artworkUrl: URL? = URL(string: "http://exponent.fm/wp-content/uploads/2014/02/cropped-Exponent-header.png")
    var mediaType: MPMediaType = .podcast
    var expectedLengthInBytes: Int64? = nil
}

class ViewController: UIViewController {
    
    @IBOutlet private var playPauseButton: UIButton!
    @IBOutlet private var backButton: UIButton!
    @IBOutlet private var forwardButton: UIButton!
    @IBOutlet private var progressBar: UIProgressView!
    @IBOutlet private var elapsedTimeLabel: UILabel!
    @IBOutlet private var remainingTimeLabel: UILabel!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private var byteRangeTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let source = TestSource()
        PlaybackController.sharedController.prepare(source, startTime: 0, playWhenReady: true)
        
        let center = NotificationCenter.default
        
        center.addObserver(forName: PlaybackControllerNotification.DidUpdateElapsedTime.name, object: nil, queue: .main) { (note) in
            let controller = PlaybackController.sharedController
            guard let duration = controller.duration else {return}
            let elapsed = floor(controller.elapsedTime)
            self.elapsedTimeLabel.text = EpisodeDurationParsing.string(from: elapsed)
            let remaining = floor(duration - elapsed)
            self.remainingTimeLabel.text = EpisodeDurationParsing.string(from: remaining)
            self.progressBar.progress = Float(elapsed / duration)
        }
        
        center.addObserver(forName: PlaybackControllerNotification.DidUpdateStatus.name, object: nil, queue: .main) { (note) in
            switch PlaybackController.sharedController.status {
            case .buffering, .preparing(_,_):
                self.activityIndicator.startAnimating()
            default:
                self.activityIndicator.stopAnimating()
            }
        }
        
        center.addObserver(forName: PlaybackControllerNotification.DidUpdateLoadedByteRanges.name, object: nil, queue: .main) { (note) in
            let key = PlaybackControllerNotification.ByteRangesKey
            if let ranges = note.userInfo?[key] as? [ByteRange] {
                self.byteRangeTextView.text = "\(ranges)"
            }
        }
        
    }
    
    @IBAction func togglePlayPause(sender: AnyObject?) {
        PlaybackController.sharedController.togglePlayPause()
    }
    
    @IBAction func back(sender: AnyObject?) {
        PlaybackController.sharedController.skipBackward()
    }
    
    @IBAction func forward(sender: AnyObject?) {
        PlaybackController.sharedController.skipForward()
    }

}
