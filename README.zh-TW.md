# Codex TPS Local

macOS 選單列的 Codex 本機用量監看工具。這個 fork 移除區網 HTTP 服務、Bonjour 公告、Gateway 探索／配對／推送、憑證儲存、CPU／網路取樣、寵物分享與上游自動更新，只保留本機日誌統計。

原始專案：[gaofeng21cn/opl-fleet-agent](https://github.com/gaofeng21cn/opl-fleet-agent)。保留原作者版權與 Apache-2.0 授權；本專案與 OpenAI 無關。[English](README.md)

## 隱私與限制

安裝版與內附快照工具使用 App Sandbox，沒有網路用戶端或伺服器權限；額外檔案權限僅為 `~/.codex/sessions/` 唯讀。使用獨立的應用程式識別碼，不匯入上游設定或鑰匙圈資料。

程式會讀取日誌位元組，但只解碼統計所需的結構欄位，不顯示、儲存或傳送對話內文。登入啟動由使用者選擇，首次安裝預設關閉。安裝版不支援自訂 Codex home。

## 安裝

需要 macOS 13 以上、Swift 6 與 Apple Command Line Tools。

```sh
git clone https://github.com/easyvibecoding/codex-tps-local.git
cd codex-tps-local
./scripts/install.sh
```

安裝位置為 `/Applications/Codex TPS Local.app`。這是從原始碼產生的本機 ad-hoc 簽章版本，**不是 Developer ID 簽章或 Apple 公證發行版**。不要關閉 Gatekeeper。沒有自動更新；後續更新需要審查並重新建置此 fork。

`--no-launch` 可略過啟動；`CODEX_TPS_LOCAL_INSTALL_DIR` 可指定其他安裝目錄。替換既有版本時會暫存舊版，驗證失敗時還原。

顯示的 TPS 是完成請求的 input + output Token 在時間窗內的平均吞吐量，包含快取 input，並非模型串流輸出速度，也不能代替帳單。

原有 Windows 程式、provider／plugin、headless Gateway agent 與上游發版機制已移除。Git 歷史仍保留上游原始內容；僅維護目前的本機版本。
