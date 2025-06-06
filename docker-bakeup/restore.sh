#!/bin/bash

# 檢查是否以 root 權限運行
if [ "$EUID" -ne 0 ]; then
  echo "錯誤：請以 sudo 執行此腳本 (sudo ./restore.sh)"
  exit 1
fi

# 檢查參數
if [ $# -lt 1 ]; then
  echo "用法: $0 <備份目錄路徑> [選項]"
  echo ""
  echo "範例:"
  echo "  $0 /home/drsite/backup/docker/php_ctf/20250605_143022"
  echo "  $0 /home/drsite/backup/docker/php_ctf/20250605_143022 --project-only"
  echo "  $0 /home/drsite/backup/docker/php_ctf/20250605_143022 --volumes-only"
  echo "  $0 /home/drsite/backup/docker/php_ctf/20250605_143022 --binds-only"
  echo ""
  echo "選項:"
  echo "  --project-only    只還原專案資料夾"
  echo "  --volumes-only    只還原 Docker volumes"
  echo "  --binds-only      只還原 bind mounts"
  echo "  --dry-run         預覽還原操作，不實際執行"
  echo "  --force           強制還原，不詢問確認"
  exit 1
fi

BACKUP_PATH="$1"
RESTORE_PROJECT=true
RESTORE_VOLUMES=true
RESTORE_BINDS=true
DRY_RUN=false
FORCE=false

# 解析選項
shift
while [ $# -gt 0 ]; do
  case $1 in
    --project-only)
      RESTORE_PROJECT=true
      RESTORE_VOLUMES=false
      RESTORE_BINDS=false
      ;;
    --volumes-only)
      RESTORE_PROJECT=false
      RESTORE_VOLUMES=true
      RESTORE_BINDS=false
      ;;
    --binds-only)
      RESTORE_PROJECT=false
      RESTORE_VOLUMES=false
      RESTORE_BINDS=true
      ;;
    --dry-run)
      DRY_RUN=true
      ;;
    --force)
      FORCE=true
      ;;
    *)
      echo "未知選項: $1"
      exit 1
      ;;
  esac
  shift
done

# 檢查備份目錄是否存在
if [ ! -d "$BACKUP_PATH" ]; then
  echo "錯誤：備份目錄 $BACKUP_PATH 不存在"
  exit 1
fi

# 檢查必要檔案
METADATA="$BACKUP_PATH/metadata.txt"
if [ ! -f "$METADATA" ]; then
  echo "錯誤：找不到 metadata.txt 檔案"
  exit 1
fi

# 從 metadata 讀取原始資訊
if ! grep -q "Project Path:" "$METADATA"; then
  echo "錯誤：metadata.txt 中找不到專案路徑資訊"
  exit 1
fi

ORIGINAL_PROJECT_PATH=$(grep "Project Path:" "$METADATA" | cut -d' ' -f3-)
DOCKER_DIR="/var/lib/docker"

# 定義備份子目錄
PROJECT_BACKUP_DIR="$BACKUP_PATH/project"
VOLUMES_BACKUP_DIR="$BACKUP_PATH/volumes"
BINDS_BACKUP_DIR="$BACKUP_PATH/binds"

echo "=================================================="
echo "Docker 備份還原腳本"
echo "=================================================="
echo "備份來源: $BACKUP_PATH"
echo "原始專案路徑: $ORIGINAL_PROJECT_PATH"
echo ""

# 顯示還原計劃
echo "還原計劃:"
if [ "$RESTORE_PROJECT" = true ]; then
  echo "  ✓ 專案資料夾: $ORIGINAL_PROJECT_PATH"
fi
if [ "$RESTORE_VOLUMES" = true ]; then
  echo "  ✓ Docker Volumes"
fi
if [ "$RESTORE_BINDS" = true ]; then
  echo "  ✓ Bind Mounts"
fi
echo ""

if [ "$DRY_RUN" = true ]; then
  echo "【預覽模式】以下操作將會執行："
  echo ""
fi

# 檢查 Docker 守護進程是否運行
if ! docker info >/dev/null 2>&1; then
  echo "錯誤：Docker 守護進程未運行，請啟動 Docker (sudo systemctl start docker)"
  exit 1
fi

# 判斷路徑是否為 btrfs subvolume
is_subvolume() {
  local path=$1
  if [ ! -e "$path" ]; then
    return 1
  fi
  local inode=$(stat -c '%i' "$path")
  if [ "$inode" = "256" ]; then
    return 0
  else
    return 1
  fi
}

# 還原 btrfs 備份
restore_btrfs_backup() {
  local backup_file=$1
  local target_path=$2
  local description=$3
  
  if [ ! -f "$backup_file" ]; then
    echo "警告：備份檔案 $backup_file 不存在，跳過 $description"
    return 1
  fi
  
  echo "還原 $description: $target_path"
  
  if [ "$DRY_RUN" = true ]; then
    echo "  [預覽] 將從 $backup_file 還原到 $target_path"
    return 0
  fi
  
  # 確保目標目錄的父目錄存在
  local parent_dir=$(dirname "$target_path")
  mkdir -p "$parent_dir" || {
    echo "錯誤：無法建立父目錄 $parent_dir"
    return 1
  }
  
  # 如果目標路徑存在，先備份
  if [ -e "$target_path" ]; then
    local backup_suffix=$(date +%Y%m%d_%H%M%S)
    local backup_target="${target_path}.backup_${backup_suffix}"
    echo "  目標路徑已存在，備份到: $backup_target"
    mv "$target_path" "$backup_target" || {
      echo "錯誤：無法備份現有路徑"
      return 1
    }
  fi
  
  # 還原 btrfs 備份
  echo "  正在還原..."
  if ! gunzip -c "$backup_file" | btrfs receive "$parent_dir" 2>/dev/null; then
    echo "錯誤：btrfs receive 失敗"
    return 1
  fi
  
  # 查找還原後的 subvolume 並重新命名
  local restored_subvol=$(find "$parent_dir" -maxdepth 1 -type d -name "*snap*" | head -n 1)
  if [ -n "$restored_subvol" ] && [ "$restored_subvol" != "$target_path" ]; then
    mv "$restored_subvol" "$target_path" || {
      echo "錯誤：無法重新命名還原的 subvolume"
      return 1
    }
  fi
  
  echo "  $description 還原完成"
  return 0
}

# 確認還原操作
if [ "$FORCE" = false ] && [ "$DRY_RUN" = false ]; then
  echo "警告：此操作將會覆蓋現有資料！"
  echo "是否繼續？(y/N)"
  read -r confirmation
  if [ "$confirmation" != "y" ] && [ "$confirmation" != "Y" ]; then
    echo "取消還原操作"
    exit 0
  fi
  echo ""
fi

# 如果要還原專案或 volumes，需要停止 Docker 服務
if [ "$RESTORE_PROJECT" = true ] || [ "$RESTORE_VOLUMES" = true ]; then
  # 檢查是否有 docker-compose.yaml 來停止服務
  if [ -f "$ORIGINAL_PROJECT_PATH/docker-compose.yaml" ]; then
    echo "停止 Docker Compose 服務..."
    if [ "$DRY_RUN" = false ]; then
      cd "$ORIGINAL_PROJECT_PATH" || {
        echo "警告：無法進入專案目錄，跳過停止服務"
      }
      docker compose stop 2>/dev/null || echo "警告：停止服務失敗或無服務運行"
    else
      echo "  [預覽] 將停止 Docker Compose 服務"
    fi
  fi
fi

# 1. 還原專案資料夾
if [ "$RESTORE_PROJECT" = true ]; then
  echo "=================================================="
  echo "還原專案資料夾"
  echo "=================================================="
  
  PROJECT_BACKUP_FILE="$PROJECT_BACKUP_DIR/full.project.btrfs.gz"
  restore_btrfs_backup "$PROJECT_BACKUP_FILE" "$ORIGINAL_PROJECT_PATH" "專案資料夾"
fi

# 2. 還原 Docker Volumes
if [ "$RESTORE_VOLUMES" = true ]; then
  echo "=================================================="
  echo "還原 Docker Volumes"
  echo "=================================================="
  
  if [ -d "$VOLUMES_BACKUP_DIR" ]; then
    for backup_file in "$VOLUMES_BACKUP_DIR"/*.btrfs.gz; do
      if [ -f "$backup_file" ]; then
        # 從檔名提取 volume 名稱
        volume_name=$(basename "$backup_file" .btrfs.gz)
        volume_path="$DOCKER_DIR/volumes/$volume_name/_data"
        
        restore_btrfs_backup "$backup_file" "$volume_path" "Volume $volume_name"
      fi
    done
  else
    echo "警告：找不到 volumes 備份目錄"
  fi
fi

# 3. 還原 Bind Mounts
if [ "$RESTORE_BINDS" = true ]; then
  echo "=================================================="
  echo "還原 Bind Mounts"
  echo "=================================================="
  
  if [ -d "$BINDS_BACKUP_DIR" ]; then
    # 從 metadata 中讀取 bind mount 對應關係
    echo "正在分析 bind mount 對應關係..."
    
    for backup_file in "$BINDS_BACKUP_DIR"/*.btrfs.gz; do
      if [ -f "$backup_file" ]; then
        # 從檔名提取編碼名稱
        encoded_name=$(basename "$backup_file" .btrfs.gz)
        
        # 從 metadata 中查找對應的原始路徑
        original_path=$(grep "發現 bind mount:" "$METADATA" | grep " -> $encoded_name" | cut -d':' -f2 | cut -d' ' -f2)
        
        if [ -n "$original_path" ]; then
          restore_btrfs_backup "$backup_file" "$original_path" "Bind mount $original_path"
        else
          echo "警告：無法找到編碼名稱 $encoded_name 對應的原始路徑"
          if [ "$DRY_RUN" = false ]; then
            echo "可以嘗試手動解碼："
            echo "  編碼名稱: $encoded_name"
            echo "  解碼命令: echo '$encoded_name' | tr '_-' '/+' | base64 -d"
          fi
        fi
      fi
    done
  else
    echo "警告：找不到 binds 備份目錄"
  fi
fi

# 重啟服務
if [ "$RESTORE_PROJECT" = true ] || [ "$RESTORE_VOLUMES" = true ]; then
  if [ -f "$ORIGINAL_PROJECT_PATH/docker-compose.yaml" ]; then
    echo "=================================================="
    echo "重新啟動 Docker Compose 服務"
    echo "=================================================="
    
    if [ "$DRY_RUN" = false ]; then
      cd "$ORIGINAL_PROJECT_PATH" || {
        echo "錯誤：無法進入專案目錄"
        exit 1
      }
      docker compose up -d || {
        echo "警告：重啟服務失敗，請手動檢查"
      }
    else
      echo "  [預覽] 將重新啟動 Docker Compose 服務"
    fi
  fi
fi

echo "=================================================="
if [ "$DRY_RUN" = true ]; then
  echo "預覽完成！"
  echo "如要執行實際還原，請移除 --dry-run 選項"
else
  echo "還原完成！"
  echo ""
  echo "注意事項："
  echo "1. 請檢查服務是否正常運行"
  echo "2. 如有問題，原始資料已備份為 *.backup_* 格式"
  echo "3. 詳細還原資訊請查看上述輸出"
fi
echo "=================================================="

exit 0
