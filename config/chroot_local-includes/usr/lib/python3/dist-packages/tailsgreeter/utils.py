import gi
from gi.repository import GLib


# GLib has idle_add_once(), but it is not exposed, so here we
# implement it ourselves.
def glib_idle_add_once(function: callable, *args, **kwargs):
    def wrapper(*_args, **_kwargs):
        function(*_args, **_kwargs)
        # Ensure this is called only once when passed to
        # GLib.idle_add().
        return False

    return GLib.idle_add(wrapper, *args, **kwargs)
