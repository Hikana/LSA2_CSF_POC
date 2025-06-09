# 🕵️ CTF 教學題目：滲透過程觀察與分析系統
這是一個專為資訊安全教學設計的 CTF 題目，模擬完整攻擊流程，並搭配內建監控系統記錄學生的攻擊行為。目的是幫助教師觀察學生解題過程、理解他們的策略與思考方式，作為後續課堂討論依據。

---
## 📂 專案結構
```
.
├── checkpermission.sh
├── ebpf.sh
└── php_ctf
    ├── alert-rules-1748981500784.json
    ├── app
    │   ├── index.php
    │   ├── init_db.php
    │   ├── reallycoolthing.jpeg
    │   ├── static
    │   │   └── uploads
    │   ├── templates
    │   │   ├── dashboard.php
    │   │   └── login.php
    │   ├── test.php
    │   ├── theacpwdbackup.jpg
    │   └── users.db
    ├── docker-compose.yaml
    ├── Dockerfile
    ├── ebpf.txt
    ├── entrypoint.sh
    ├── local-config.yaml
    ├── New dashboard-1748982322119.json
    ├── nginx.conf
    ├── nginx_logs
    │   ├── access.log
    │   └── error.log
    ├── prometheus.yml
    └── promtail-config.yml
```

---

## 🚀 快速開始

### 環境需求
- Docker
- Docker Compose

### 啟動服務

```bash
git clone https://github.com/Hikana/LSA2_CSF_POC.git
cd ./final/php_ctf
sudo docker-compose up --build -d
```

- 補充：重開題目指令
```bash
sudo docker-compose down
sudo docker-compose up --build -d
```

## 題目畫面
登入頁面<br>
![rkT8hzVmll](https://github.com/user-attachments/assets/58039c54-2ecb-4cb4-b960-8e54d2c4b01d)
<br>上傳檔案頁面<br>
![SknunzVXlg](https://github.com/user-attachments/assets/3a3cae14-d46a-4ddd-b463-d3919891fb4b)

## 🎯 題目設計說明
### 題目目標
參賽者需利用 SQLi 登入管理介面，繞過目錄限制讀取敏感檔案，取得帳號密碼，並上傳 Webshell 進行 RCE，最終找到並讀取 FLAG。<br>

### 題目特色
模擬真實滲透流程<br>
多層次攻擊：SQLi → Local File Inclusion → Reverse Shell → 提權 <br>
內建監控系統，記錄參賽者操作行為方便回顧與教學<br>

## 監控系統介紹

🐳 DockerInside-part
本區塊主要負責監控容器內部的行為與流量，搭配以下 Framwork：

🔧 Nginx + promtail + Loki + Grafana
Nginx：作為前端 Web 伺服器，提供基礎反向代理並寫入詳細的 access.log 與 error.log。

Promtail：負責收集容器內 Nginx 的 log 並傳送至 Loki。

Loki：一套類似 Elasticsearch 的日誌儲存與查詢系統，專門針對時間序列 log 設計。

Grafana：透過視覺化面板整合 Loki 與 Prometheus 資料來源，提供即時 log 查詢與儀表板展示。

Prometheus : 擔任容器環境中的 metric 收集器，定期抓取系統指標（如 CPU、記憶體使用量、HTTP 回應狀態碼分布等）。

搭配 Grafana 可呈現異常行為趨勢，如：突增的 HTTP 請求、異常高的記憶體使用量。

![image](https://github.com/user-attachments/assets/338fd826-8748-4e95-94c7-58e09b2bed6e)


🖥️ Shell-part
主機層面的行為則透過 Shell script 搭配 eBPF (bpftrace) 實作低層級的系統監控。

📝 ebpf.sh
簡單檢查容器內是否被入侵或取得額外權限，例如讀取本不應訪問的檔案或系統資訊。

🐾 ebpf.sh + bpftrace
使用 eBPF 技術追蹤系統呼叫（如 open(), execve() 等）。

可即時紀錄使用者在容器內部執行的指令，包含 reverse shell、上傳 webshell 後執行的惡意 payload 等。

🚨 警示機制（Alerting System）

透過 Grafana 自身內建的 Alerting 模組 進行即時異常偵測，並結合 dcwebhook 發送通知，以達成自動化告警功能。


最終結構
![image](https://github.com/user-attachments/assets/bc8e6e4a-930b-4da2-af9e-2690c2c03746)



