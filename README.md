# sodes-audio-example
An example AVResourceLoaderDelegate implementation.

## What It Does

Contains an example implementation of an AVAssetResourceLoaderDelegate which downloads the requested byte range to a "scratch file." It also re-uses previously-downloaded byte ranges from that scratch file to service future requests that overlap those byte ranges, both during the current app session and in future sessions.

It also contains an example application so you can see it in action.

## Sample App Screenshot

You can see below some basic play controls, as well as a text view that prints out the byte ranges that have been successfully written to the current scratch file. 

Delete and reinstall the app to clear out the scratch file (or change the hard-coded MP3 URL to some other MP3 url and rebuild and run).

<img src="https://raw.githubusercontent.com/jaredsinclair/sodes-audio-example/master/screenshot.png" width="375">
