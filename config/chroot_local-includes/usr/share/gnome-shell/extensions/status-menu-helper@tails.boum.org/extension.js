/**
   Copyright (C) 2014 Raphael Freudiger <laser_b@gmx.ch>
   Copyright (C) 2014 Jonatan Zeidler <jonatan_zeidler@gmx.de>
   Copyright (C) 2014-2017 Tails Developers <tails@boum.org>

   This program is free software: you can redistribute it and/or
   modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, either version 2 of the
   License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.

   status-menu-helper is based on gnome-shell-extension-suspend-button
   (https://github.com/laserb/gnome-shell-extension-suspend-button) by
   Raphael Freudiger <laser_b@gmx.ch>.
**/
const Lang = imports.lang;
const Main = imports.ui.main;
const PopupMenu = imports.ui.popupMenu;

const Gettext = imports.gettext.domain('tails');
const _ = Gettext.gettext;

const Me = imports.misc.extensionUtils.getCurrentExtension();
const Lib = Me.imports.lib;

const Util = imports.misc.util;

var Action = new Lang.Class({
    Name: 'Action',

    _init: function(button, id) {
        this.button = button;
        this.id = id;
    }
});

const Extension = new Lang.Class({
    Name: 'StatusMenuHelper.Extension',

    enable: function() {
        if (this._isEnabled) return;
        this._isEnabled = true;

        this.statusMenu = Main.panel.statusArea.quickSettings;

        statusMenuTopButtons = this.statusMenu._system._systemItem.child.get_children();
        for (var item of statusMenuTopButtons) {
            if (item.constructor.name == "LockItem") {
                this._origLockItem = item;
            } else if (item.constructor.name == "ShutdownItem") {
                this._origShutdownItem = item;
            }
        }

        this._createActions();
        this._hideOrigActions();
        this._addSeparateButtons();

        this._menuOpenStateChangedId = this.statusMenu.menu.connect('open-state-changed', (menu, open) => {
            if (!open)
                return;
            this._onMenuOpen();
        });
    },

    disable: function() {
        // We want to keep the extention enabled on the lock screen
        if (Main.sessionMode.isLocked) return;
        if (!this._isEnabled) return;
        this._isEnabled = false;

        this._destroyActions();
        this._restoreOrigActions();

        this.statusMenu.menu.disconnect(this._menuOpenStateChangedId);
    },

    _createActions: function() {
        this._lockScreenAction = this._createAction(_("Lock Screen"),
                                                   'changes-prevent-symbolic',
                                                    this._onLockClicked);

        this._suspendAction = this._createAction(_("Suspend"),
                                                 'media-playback-pause-symbolic',
                                                 this._onSuspendClicked);

        this._restartAction = this._createAction(_("Restart"),
                                                 'view-refresh-symbolic',
                                                 this._onRestartClicked);

        this._powerOffAction = this._createAction(_("Power Off"),
                                                  'system-shutdown-symbolic',
                                                  this._onPowerOffClicked);

        this._actions = [this._lockScreenAction, this._suspendAction,
                         this._restartAction, this._powerOffAction];
    },

    _createAction: function(label, icon, onClickedFunction) {
        item = new PopupMenu.PopupImageMenuItem(label, icon);
        item.connect('activate', onClickedFunction);
        return item;
    },

    _hideOrigActions: function() {
        this._origLockItem.hide();
        this._origShutdownItem.hide();
    },

    _restoreOrigActions: function() {
        this._origLockItem.show();
        this._origShutdownItem.show();
    },

    _addSeparateButtons: function() {
        this.statusMenu._addItems(this._actions);
    },

    _destroyActions: function() {
        for (var item of this._actions) {
            item.destroy();
        }
    },

    _onLockClicked: function() {
        Util.spawn(['tails-screen-locker']);
    },

    _onSuspendClicked: function() {
        Util.spawn(['systemctl', 'suspend'])
    },

    _onRestartClicked: function() {
        Util.spawn(['sudo', '-n', 'reboot'])
    },

    _onPowerOffClicked: function() {
        Util.spawn(['sudo', '-n', 'poweroff'])
    },

    _onMenuOpen: function() {
        this._lockScreenAction.visible = !Main.sessionMode.isLocked && !Main.sessionMode.isGreeter;
        // Ideally we would only have to hide the original actions in
        // the enable() method, but something keeps making the original
        // shutdown action visible, so we ensure it is hidden each time
        // the menu is opened.
        this._hideOrigActions();
    }

});

function init(metadata) {
    Lib.initTranslations(Me);
    return new Extension();
}
