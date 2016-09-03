# sodes-audio-example

An example AVAssetResourceLoaderDelegate implementation. A variation of this will be used in **’sodes**, a podcast app I'm working on.

You are welcome to use this code as allowed under the generous terms of the MIT License, but **this code is not intended to be used as a re-usable library**. It's highly optimized for the needs of my particular app. I'm sharing it here for the benefit of anyone who's looking for an example of how to write an AVAssetResourceLoaderDelegate implementation.

## What It Does

Contains an example implementation of an AVAssetResourceLoaderDelegate which downloads the requested byte ranges to a "scratch file" of locally-cached byte ranges. It also re-uses previously-downloaded byte ranges from that scratch file to service future requests that overlap the downloaded byte ranges, both during the current app session and in future sessions. This helps limit the number of times the same bits are downloaded when streaming a podcast episode over more than one app session. Ideally each bit should only ever be downloaded once.

When a request for a byte range is sent to the resource loader delegate, an array of "subrequests" is formed which are either scratch file requests or network requests. Scratch file requests read the data from existing byte ranges in the scratch file which have already been downloaded. Network requests are made for any gaps in the scratch file. The results of network requests are both passed to the AVAssetResourceLoader and written to the scratch file to be re-used later if the need arises.

## TL;DR Files

- [ResourceLoaderDelegate.swift](https://github.com/jaredsinclair/sodes-audio-example/blob/master/Sodes/SodesAudio/ResourceLoaderDelegate.swift)
- [DataRequestLoader.swift](https://github.com/jaredsinclair/sodes-audio-example/blob/master/Sodes/SodesAudio/DataRequestLoader.swift)
- [ResourceLoaderSubrequest.swift](https://github.com/jaredsinclair/sodes-audio-example/blob/master/Sodes/SodesAudio/ResourceLoaderSubrequest.swift)
- [PlaybackController.swift](https://github.com/jaredsinclair/sodes-audio-example/blob/master/Sodes/SodesAudio/PlaybackController.swift)

## Sample App Screenshot

This repository also contains an example application so you can see it in action.

You can see below some basic play controls, as well as a text view that prints out the byte ranges that have been successfully written to the current scratch file. 

Delete and reinstall the app to clear out the scratch file (or change the hard-coded MP3 URL to some other MP3 url and rebuild and run).

<img src="https://raw.githubusercontent.com/jaredsinclair/sodes-audio-example/master/screenshot.png" width="375">

## Acknowledgements

Contains a modified copy of [CommonCryptoSwift](https://github.com/onmyway133/Arcane), a convenient wrapper around CommonCrypto that can be used in a Swift framework.
