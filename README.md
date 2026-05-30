# aaAI-Free

Unlock aaPanel AI Assistant so your **own API keys** always work — even when aaPanel official quota runs out or the server is unreachable.

## Problem

aaPanel AI Assistant (AICS) routes everything through `aapanel.com`:

```
Your Panel ──→ aapanel.com proxy ──→ AI provider (qwen, doubao, etc.)
                    │
                    └── Controls: quota, PRO status, model list
```

When the server returns `remaining=0` (quota exhausted) **or is simply down**:

- `has_quota` = `False` → **ALL AI features stop working**
- Even custom API keys you added won't work
- The AI chat panel goes blank

## Solution

aaAI-Free patches the controller at runtime:

```
Your Panel ──→ YOUR API key ──→ AI provider directly
                (DeepSeek, OpenAI, etc.)

✓ No aaPanel server dependency
✓ No quota limits
✓ No PRO paywall
✓ Your custom models always work
```

## How it works

A tiny Python module (`aaai_free.py`) hooks into the AICS module loader and patches 3 methods on the `main` controller class:

| Patch | Method | Effect |
|-------|--------|--------|
| 1 | `_shared_state` | Forces `has_quota=True`, `is_pro=True` permanently |
| 2 | `pro_auth()` | Always reports PRO license active |
| 3 | `get_config()` | Overrides server response to keep quota + PRO on |

**Zero modification to encrypted files.** The patch only touches `agent.py` (plaintext) to add one import line.

## Install

```bash
git clone https://github.com/trvanthanhhmaster-spec/aaai-free.git
cd aaai-free
sudo bash install.sh
```

Then restart aaPanel (or just the AI plugin).

## Uninstall

```bash
sudo bash install.sh --uninstall
```

## Requirements

- aaPanel with AI Assistant (AICS) installed
- At least one custom API account configured ("Tài khoản và mô hình của tôi")

## Files

```
aaai-free/
├── aaai_free.py    # The patch module
├── install.sh      # Installer script
└── README.md       # This file
```

## Disclaimer

This tool is for users who want to use their own paid API keys directly. It does NOT:
- Steal API keys
- Bypass API provider billing (you still pay DeepSeek/OpenAI directly)
- Modify any encrypted or proprietary code

## License

MIT
