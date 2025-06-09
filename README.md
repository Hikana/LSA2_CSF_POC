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

:::spoiler
- 補充：重開題目指令
```bash
sudo docker-compose down
sudo docker-compose up --build -d
```
:::

## 題目畫面
登入頁面
![image](https://hackmd.io/_uploads/rkT8hzVmll.png)
上傳檔案頁面
![image](https://hackmd.io/_uploads/SknunzVXlg.png)

## 🎯 題目設計說明
### 題目目標：
參賽者需利用 SQLi 登入管理介面，繞過目錄限制讀取敏感檔案，取得帳號密碼，並上傳 Webshell 進行 RCE，最終找到並讀取 FLAG。

### 題目特色
模擬真實滲透流程
多層次攻擊：SQLi → Local File Inclusion → Reverse Shell → 提權
內建監控系統，記錄參賽者操作行為方便回顧與教學

## 監控系統介紹













