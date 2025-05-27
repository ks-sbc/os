const Main = imports.ui.main;
const GLib = imports.gi.GLib;

const ExtensionUtils = imports.misc.extensionUtils;
const ByteArray = imports.byteArray;

var settings;

function init() {
}

function overrider(lbl) {
    var now = new Date();
    let [res, out] = GLib.spawn_sync(null, ['sudo', '-n', '/usr/local/lib/tails-get-date'], null, GLib.SpawnFlags.SEARCH_PATH, null);
    if(out == null) {
        var desired = now.toLocaleString('en-US') + ' GMT';
    } else {
        desired = ByteArray.toString(out).trim();
    }

    var t = lbl.get_text();
    if (t != desired) {
        last = t;
        lbl.set_text(desired);
    }
}

var lbl, signalHandlerID, last = "";

function enable() {
    var sA = Main.panel.statusArea;
    if (!sA) { sA = Main.panel._statusArea; }

    if (!sA || !sA.dateMenu) {
        print("Looks like Shell has changed where things live again; aborting.");
        return;
    }

    sA.dateMenu.first_child.get_children().forEach(function(w) {
        // assume that the text label is the first StLabel we find.
        // This is dodgy behaviour but there's no reliable way to
        // work out which it is.
        w.set_style("text-align: center;");
        if (w.get_text && !lbl) {
            lbl = w;
        }
    });
    if (!lbl) {
        print("Looks like Shell has changed where things live again; aborting.");
        return;
    }
    signalHandlerID = lbl.connect("notify::text", overrider);
    last = lbl.get_text();
    overrider(lbl);
}

function disable() {
    if (lbl && signalHandlerID) {
        lbl.disconnect(signalHandlerID);
        lbl.set_text(last);
    }
}
