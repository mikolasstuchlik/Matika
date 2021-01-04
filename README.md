# Matika - a SwiftGtk demonstrator

Matika (Czech slang word for "math") is a simple demonstrator for SwiftGtk - Swift package providing interface for Gtk.

Matika is a real-world example of simple application that could be built using SwiftGtk.

## Building

### Ubuntu 20.04 LTS
First you need to install prerequisities. On Ubuntu 20.04 you can do so using `apt`:

```bash
sudo apt update
sudo apt install libgtk-3-dev gir1.2-gtksource-3.0 gobject-introspection libgirepository1.0-dev libxml2-dev jq
```
Since SwiftGtk takes advantage of generated code, you need to run generator first. For that purpose, you can use `run-gir2swift.sh`.
```bash
./run-gir2swift.sh
```
This script will trigger dependency fetch, compiles the code generator and runs it.

Then you can build & run the application using SPM:
```bash
swift run
```
### macOS Big Sur
The supported version of Xcode is 12.2.

First you need to install prerequisities. On macOS 11 you can do so using `apt`:

```bash
brew install glib gobject-introspection pango atk gtk+3 cairo glib-networking gdk-pixbuf
```
Since SwiftGtk takes advantage of generated code, you need to run generator first. For that purpose, you can use `run-gir2swift.sh`.
```bash
./run-gir2swift.sh
```
This script will trigger dependency fetch, compiles the code generator and runs it.

Then you can build & run the application using SPM. At the time of writing, there is a bug in SPM which may be resolved in Swift 5.4. As a fix, you need to append your build commands by ``./run-gir2swift.sh flags -noUpdate`` which will scan your project and provide compiler and linker with appropriate configuration.
```bash
swift run `./run-gir2swift.sh flags -noUpdate`
```

<!-- 
echo '#!/bin/bash

## Swift package with fetched dependencies is required to run scipt in gir2swift package. Use option -noUpdate to prevent update. 
if ! [[ $@ == *'-noUpdate'* ]]
then
    swift package update  
fi

case $1 in
## Returns flags needed for macOS compilation (experimental)
flags) .build/checkouts/gir2swift/gir2swift-generation-driver.sh c-flags $PWD ;;
## Removes all generaed files
clean) .build/checkouts/gir2swift/gir2swift-generation-driver.sh remove-generated $PWD ;;
## Defaults to generation
*) .build/checkouts/gir2swift/gir2swift-generation-driver.sh generate $PWD ;;
esac
' > run-gir2swift.sh && chmod u+x run-gir2swift.sh -->
