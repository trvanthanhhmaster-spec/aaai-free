"""
aaAI-Free — Unlock aaPanel AI Assistant with your own API keys.

Forces has_quota=True and is_pro=True so custom API accounts work
even when aaPanel official quota is exhausted or server is unreachable.

Source: https://github.com/trvanthanhhmaster-spec/aaai-free
License: MIT
"""

import sys

PANEL_LOG = "/www/server/panel/data/agent/aaai_free.log"
PATCHED = False


def _log(msg: str):
    try:
        with open(PANEL_LOG, "a") as f:
            f.write(f"[aaai-free] {msg}\n")
    except Exception:
        pass


def _apply_patches(main_cls):
    """Apply all patches to the main controller class (runs once)."""
    global PATCHED
    if PATCHED:
        return
    PATCHED = True

    # --------------------------------------------------------------
    # 1. Force class-level shared state — the master switch.
    # --------------------------------------------------------------
    main_cls._shared_state["has_quota"] = True
    main_cls._shared_state["is_pro"] = True

    # --------------------------------------------------------------
    # 2. pro_auth: always report PRO = True.
    # --------------------------------------------------------------
    _orig_pro_auth = main_cls.pro_auth

    def patched_pro_auth(self, get=None):
        self.config["is_pro"] = True
        main_cls._shared_state["is_pro"] = True
        try:
            return _orig_pro_auth(self, get)
        except Exception:
            return True

    main_cls.pro_auth = patched_pro_auth

    # --------------------------------------------------------------
    # 3. get_config: force has_quota + is_pro AFTER server response.
    # --------------------------------------------------------------
    _orig_get_config = main_cls.get_config

    def patched_get_config(self, get):
        result = _orig_get_config(self, get)
        self.config["has_quota"] = True
        self.config["is_pro"] = True
        main_cls._shared_state["has_quota"] = True
        main_cls._shared_state["is_pro"] = True
        # Downgrade PRO models to free
        models = self.config.get("models", {})
        if isinstance(models, dict):
            for model_list in models.values():
                for m in model_list:
                    if isinstance(m, dict) and m.get("auth") == 1:
                        m["auth"] = 0
        return result

    main_cls.get_config = patched_get_config

    _log("All patches applied to main class.")


def _wrap_plugin_loader():
    """
    Wrap PluginLoader.get_module so that every time comMod is loaded
    (decrypted + compiled by the .so), we immediately patch the main class.
    """
    try:
        import PluginLoader
    except ImportError:
        _log("PluginLoader not available yet, will retry later.")
        return

    _orig_get_module = PluginLoader.get_module

    def patched_get_module(filename: str):
        module = _orig_get_module(filename)
        if isinstance(module, dict):
            return module  # Error response, pass through
        if hasattr(module, "main"):
            _apply_patches(module.main)
        return module

    PluginLoader.get_module = patched_get_module
    _log("PluginLoader.get_module wrapped successfully.")


# --- Run at import time ---

# Strategy A: Patch comMod immediately if it's already in sys.modules
# (When aaai_free is imported from agent.py during comMod's own loading,
# comMod might already be registered in sys.modules by PluginLoader.)
for _name, _mod in list(sys.modules.items()):
    if hasattr(_mod, "main") and hasattr(_mod.main, "_shared_state"):
        _apply_patches(_mod.main)
        _log(f"Patched via sys.modules scan: {_name}")
        break

# Strategy B: Wrap PluginLoader.get_module to patch on every future load.
# This catches cases where Strategy A didn't fire (e.g. sys.modules
# entry hadn't been created yet when this module was first imported).
_wrap_plugin_loader()
