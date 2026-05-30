# aaAI-Free / Mở khóa aaPanel AI Assistant

[Tiếng Việt](#tiếng-việt) | [English](#english)

---

## Tiếng Việt

### Vấn đề

aaPanel AI Assistant (AICS) định tuyến mọi yêu cầu qua máy chủ `aapanel.com`:

```
Panel của bạn ──→ aapanel.com proxy ──→ Nhà cung cấp AI (qwen, doubao, ...)
                        │
                        └── Kiểm soát: quota, trạng thái PRO, danh sách model
```

Khi máy chủ aaPanel hết quota **hoặc đơn giản là sập**:

- `has_quota` = `False` → **toàn bộ tính năng AI ngừng hoạt động**
- Ngay cả API key của riêng bạn cũng không dùng được
- Bảng chat AI trống trơn

### Giải pháp

aaAI-Free vá controller lúc runtime:

```
Panel của bạn ──→ API key CỦA BẠN ──→ Nhà cung cấp AI trực tiếp
                  (DeepSeek, OpenAI, ...)

✓ Không phụ thuộc máy chủ aaPanel
✓ Không giới hạn quota
✓ Không rào cản PRO
✓ Model tùy chỉnh luôn hoạt động
```

### Cách hoạt động

Module Python nhỏ gọn (`aaai_free.py`) hook vào trình tải module AICS và vá 3 phương thức của class `main`:

| Vá | Phương thức | Hiệu quả |
|-------|--------|--------|
| 1 | `_shared_state` | Ép `has_quota=True`, `is_pro=True` vĩnh viễn |
| 2 | `pro_auth()` | Luôn báo cáo license PRO hợp lệ |
| 3 | `get_config()` | Ghi đè phản hồi từ server, giữ quota + PRO luôn bật |

**Không sửa đổi file mã hóa.** Chỉ thêm 1 dòng import vào `agent.py` (file plaintext).

### Cài đặt

```bash
git clone https://github.com/trvanthanhhmaster-spec/aaai-free.git
cd aaai-free
sudo bash install.sh
```

Sau đó khởi động lại aaPanel (hoặc chỉ plugin AI).

### Gỡ cài đặt

```bash
sudo bash install.sh --uninstall
```

### Yêu cầu

- aaPanel đã cài AI Assistant (AICS)
- Ít nhất 1 tài khoản API tùy chỉnh ("Tài khoản và mô hình của tôi")

### Tuyên bố miễn trừ trách nhiệm

Công cụ này dành cho người dùng muốn sử dụng API key của chính họ một cách trực tiếp. Công cụ này KHÔNG:
- Đánh cắp API key
- Vượt qua thanh toán của nhà cung cấp API (bạn vẫn trả tiền trực tiếp cho DeepSeek/OpenAI)
- Sửa đổi bất kỳ code mã hóa hoặc độc quyền nào

### Giấy phép

MIT

---

## English

### Problem

aaPanel AI Assistant (AICS) routes everything through `aapanel.com`:

```
Your Panel ──→ aapanel.com proxy ──→ AI provider (qwen, doubao, etc.)
                    │
                    └── Controls: quota, PRO status, model list
```

When the aaPanel server runs out of quota **or simply goes down**:

- `has_quota` = `False` → **all AI features stop working**
- Even your own custom API keys won't work
- The AI chat panel goes blank

### Solution

aaAI-Free patches the controller at runtime:

```
Your Panel ──→ YOUR API key ──→ AI provider directly
                (DeepSeek, OpenAI, etc.)

✓ No aaPanel server dependency
✓ No quota limits
✓ No PRO paywall
✓ Your custom models always work
```

### How it works

A tiny Python module (`aaai_free.py`) hooks into the AICS module loader and patches 3 methods on the `main` controller class:

| Patch | Method | Effect |
|-------|--------|--------|
| 1 | `_shared_state` | Forces `has_quota=True`, `is_pro=True` permanently |
| 2 | `pro_auth()` | Always reports PRO license active |
| 3 | `get_config()` | Overrides server response to keep quota + PRO on |

**Zero modification to encrypted files.** The patch only touches `agent.py` (plaintext) to add one import line.

### Install

```bash
git clone https://github.com/trvanthanhhmaster-spec/aaai-free.git
cd aaai-free
sudo bash install.sh
```

Then restart aaPanel (or just the AI plugin).

### Uninstall

```bash
sudo bash install.sh --uninstall
```

### Requirements

- aaPanel with AI Assistant (AICS) installed
- At least one custom API account configured ("My accounts and models")

### Disclaimer

This tool is for users who want to use their own paid API keys directly. It does NOT:
- Steal API keys
- Bypass API provider billing (you still pay DeepSeek/OpenAI directly)
- Modify any encrypted or proprietary code

### License

MIT
