/*
  No overview at start-up
  Contributors: @fthx, @fmuellner
  License: GPL v3
*/


const Main = imports.ui.main;


class Extension {
    constructor() {
        this._realHasOverview = Main.sessionMode.hasOverview;
    }

    enable() {
        if (!Main.layoutManager._startingUp) {
            return;
        }

        /*
          Since we are based on Debian Bookworm we run GNOME 43 and
          the appropriate version of this extension is version 13,
          which simply sets `hasOverview = false` straight in
          enable(), i.e. the Activities Overview is disabled early in
          GNOME's startup, when extensions are enabled. This
          interferes with the window-list extension, making it
          impossible to exit from the Activities Overview. We work
          around this by instead delaying that to when GNOME's
          startup-prepared signal is emitted.

          If you look at the code in gnome-shell-43.9/js/ui/layout.js
          you can see that after `this.emit('startup-prepared')` it
          calls `_startupAnimation()`, and in all the three paths it
          can take we quickly end up in `_startupAnimationComplete()`
          which emits the startup-complete signal. So very little
          happens in-between, which probably is why this workaround
          seems to work fine.
         */
        Main.layoutManager.connect('startup-prepared', () => {
            Main.sessionMode.hasOverview = false;
        });

        Main.layoutManager.connect('startup-complete', () => {
            Main.sessionMode.hasOverview = this._realHasOverview;
        });
    }

    disable() {
        Main.sessionMode.hasOverview = this._realHasOverview;
    }
}

function init() {
    return new Extension();
}
