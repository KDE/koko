/*
 * SPDX-FileCopyrightText: (C) 2021 Mikel Johnson <mikel5764@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick
import QtQuick.Window
import QtQuick.Controls as Controls
import org.kde.koko as Koko

// This object manages slideshows.
// It abstract the implementation with a clean and simple API,
// so you only need to bother about *what* to do, not *how*

Item {
    id: root

    // this property indicates whether slideshow is running
    // this includes external media even while the timer is paused
    // *read only* (not programmatically but this will break if you write to this)
    property bool running: false

    // this property indicates whether external media is running
    // *read only*
    property bool externalMediaRunning: false

    // save last window state before running slideshow
    property int lastWindowVisibility: (Controls.ApplicationWindow.window as Koko.Main).visibility
    property bool lastControlsVisible: (Controls.ApplicationWindow.window as Koko.Main).controlsVisible

    // start the slideshow
    // don't use these function for anything else
    // besides actually starting and stopping the presentation
    // since this is reflected in UI unlike functions below these
    function start(): void {
        running = true;
        root.lastWindowVisibility = (Controls.ApplicationWindow.window as Koko.Main).visibility;
        root.lastControlsVisible = (Controls.ApplicationWindow.window as Koko.Main).controlsVisible;
        (Controls.ApplicationWindow.window as Koko.Main).visibility = Window.FullScreen;
        (Controls.ApplicationWindow.window as Koko.Main).controlsVisible = false;
        slideshowTimer.restart();
    }

    // stop the slideshow
    function stop(): void {
        running = false;
        externalMediaRunning = false;
        (Controls.ApplicationWindow.window as Koko.Main).visibility = root.lastWindowVisibility;
        (Controls.ApplicationWindow.window as Koko.Main).controlsVisible = root.lastControlsVisible;
        slideshowTimer.stop();
    }

    // since all the logic is done by using the following functions
    // it's pretty easy to plop log() here to simplify debugging

    // call this when you need show media that isn't static (i.e. video) to pause the timer
    function externalPlaybackStarted(): void {
        externalMediaRunning = true;
        slideshowTimer.stop();
    }

    // call this when when your playback has finished to move immediately to the next slide
    // and resume the timer
    function externalPlaybackFinished(): void {
        externalMediaRunning = false;
        triggered();
        slideshowTimer.restart();
    }

    // call this when when your playback has unloaded to resume the timer
    // without immediately moving to the next slide
    function externalPlaybackUnloaded() {
        externalMediaRunning = false;
        slideshowTimer.restart();
    }

    // this will be called whenever new slide is required
    signal triggered()

    // internal object, do *not* call from outside
    Timer {
        id: slideshowTimer
        interval: Koko.Config.nextImageInterval * 1000
        repeat: true
        onTriggered: {
            if (parent.externalMediaRunning) {
                stop();
                return;
            }
            parent.triggered();
        }
    }
}
