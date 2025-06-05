#!/bin/bash

# 檢查是否以 root 權限運行
if [ "$EUID" -ne 0 ]; then
  echo "錯誤：請以 sudo 執行此腳本 (sudo ./bkup.sh)"
  exit 1
fi

# 定義時間戳和備份目錄
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DOCKER_DIR="/var/lib/docker"
SOURCE_DIR="/home/drsite/project/php_ctf"
BACKUP_DIR="/home/drsite/backup/docker"
CURRENT_DIR=$(basename "$SOURCE_DIR")

# 取得專案資料夾的絕對路徑，用於後續比對
PROJECT_ABS_PATH=$(realpath "$SOURCE_DIR")

# 定義備份子目錄
BACKUP_BASE="$BACKUP_DIR/$CURRENT_DIR/$TIMESTAMP"
PROJECT_BACKUP_DIR="$BACKUP_BASE/project"
VOLUMES_BACKUP_DIR="$BACKUP_BASE/volumes"
BINDS_BACKUP_DIR="$BACKUP_BASE/binds"

# 檢查 Btrfs
check_btrfs() {
  local path=$1
  if ! df -T "$path" | grep -q btrfs; then
    echo "錯誤：$path 不是 Btrfs 文件系統"
    exit 1
  fi
}

check_btrfs "$BACKUP_DIR"
check_btrfs "$SOURCE_DIR/.."

# 創建備份目錄結構
mkdir -p "$PROJECT_BACKUP_DIR" || { 
  echo "創建專案備份目錄失敗"; exit 1; 
}
mkdir -p "$VOLUMES_BACKUP_DIR" || { 
  echo "創建 volumes 備份目錄失敗"; exit 1; 
}
mkdir -p "$BINDS_BACKUP_DIR" || { 
  echo "創建 binds 備份目錄失敗"; exit 1; 
}
mkdir -p "$SOURCE_DIR/../${CURRENT_DIR}_snap_tmp"

# 檢查 docker-compose.yaml 是否存在
if [ ! -f "$SOURCE_DIR/docker-compose.yaml" ]; then
  echo "錯誤：docker-compose.yaml 不存在於當前目錄"
  exit 1
fi

# 創建 metadata 檔案
METADATA="$BACKUP_BASE/metadata.txt"
echo "Backup Time: $TIMESTAMP" > "$METADATA"
echo "Project Path: $PROJECT_ABS_PATH" >> "$METADATA"
echo "===========================================" >> "$METADATA"

# 檢查 Docker 守護進程是否運行
if ! docker info >/dev/null 2>&1; then
  echo "錯誤：Docker 守護進程未運行，請啟動 Docker (sudo systemctl start docker)"
  exit 1
fi

# 判斷路徑是否為 btrfs subvolume（inode 是否為 256）
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

# 檢查路徑是否在專案資料夾內
is_path_in_project() {
  local path=$1
  local abs_path=$(realpath "$path" 2>/dev/null)
  
  # 如果無法取得絕對路徑，視為不在專案內
  if [ -z "$abs_path" ]; then
    return 1
  fi
  
  # 檢查是否為專案路徑的子路徑
  case "$abs_path" in
    "$PROJECT_ABS_PATH"*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# 備份路徑（非子卷時先轉換為 subvolume）
create_subvolume() {
  local volume_name=$1
  local volume_path=$2
  local backup_base=$3
  local backup_path="$backup_base/${volume_name}_backup_$TIMESTAMP"

  echo "非子卷，備份整個路徑 $volume_path 到 $backup_path" >> "$METADATA"
  mkdir -p "$backup_base" || { 
    echo "建立備份目錄 $backup_base 失敗"; return 1; 
  }

  # 複製資料到備份目錄
  rsync -a "$volume_path/" "$backup_path/" || { 
    echo "備份路徑 $volume_path 失敗"; return 1; 
  }

  # 刪除原本路徑的資料，重新建立 subvolume
  echo "刪除原路徑資料 $volume_path" >> "$METADATA"
  rm -rf "$volume_path" || { 
    echo "刪除路徑資料失敗"; return 1; 
  }

  # 建立 subvolume
  btrfs subvolume create "$volume_path" || {
    echo "建立 subvolume 失敗"; return 1;
  }

  echo "還原備份資料回路徑 $volume_path" >> "$METADATA"
  rsync -a "$backup_path/" "$volume_path/" || { 
    echo "還原備份資料失敗"; return 1; 
  }

  # 清理暫存備份
  rm -rf "$backup_path" || echo "清理暫存備份失敗" >> "$METADATA"

  echo "路徑轉換為 subvolume 完成: $volume_path" >> "$METADATA"
}

# 執行 btrfs 快照備份
perform_btrfs_backup() {
  local source_path=$1
  local backup_file=$2
  local backup_file_end=$3
  local snap_name=$4
  local description=$5
  
  echo "開始 $description 備份: $source_path"
  
  # 檢查是否為 subvolume，如果不是則先轉換
  if ! is_subvolume "$source_path"; then
    echo "$description 非 subvolume，轉換為 subvolume" >> "$METADATA"
    local temp_name=$(basename "$source_path" | tr '/' '_')
    mkdir -p "/tmp/btrfs_convert"
    create_subvolume "$temp_name" "$source_path" "/tmp/btrfs_convert"
    rm -rf "/tmp/btrfs_convert"
  fi
  
  local snap_new="$SOURCE_DIR/../${CURRENT_DIR}_snap_tmp/${snap_name}_$TIMESTAMP"
  local old_snap=$(find "$SOURCE_DIR/../${CURRENT_DIR}_snap_tmp/" -maxdepth 1 -type d -name "${snap_name}_*" ! -name "${snap_name}_$TIMESTAMP" | head -n 1)
  
  # 建立新的 readonly snapshot
  btrfs subvolume snapshot -r "$source_path" "$snap_new" || {
    echo "$description snapshot 建立失敗" >> "$METADATA"
    return 1
  }
  
  # 執行增量或完整備份
  if [ -d "$old_snap" ]; then
    echo "執行 $description 增量備份" >> "$METADATA"
    btrfs send -p "$old_snap" "$snap_new" | gzip > "${backup_file}/incre${backup_file_end}" || {
      echo "$description 增量備份失敗" >> "$METADATA"
      return 1
    }
    # 刪除舊的 snapshot
    btrfs subvolume delete "$old_snap" || echo "刪除舊 $description snapshot 失敗" >> "$METADATA"
  else
    echo "執行 $description 完整備份" >> "$METADATA"
    btrfs send "$snap_new" | gzip > "${backup_file}/full${backup_file_end}" || {
      echo "$description 完整備份失敗" >> "$METADATA"
      return 1
    }
  fi
  
  echo "$description 備份完成: $backup_file" >> "$METADATA"
  return 0
}

# 1. 備份整個專案資料夾
echo "===========================================" >> "$METADATA"
echo "開始備份專案資料夾" >> "$METADATA"
echo "開始備份專案資料夾: $PROJECT_ABS_PATH"

perform_btrfs_backup "$PROJECT_ABS_PATH" "$PROJECT_BACKUP_DIR" ".project.btrfs.gz" "project_snap" "專案資料夾"

echo "專案資料夾備份完成" >> "$METADATA"

# 從 docker-compose.yaml 讀取服務
cd "$SOURCE_DIR" || { echo "無法進入 $SOURCE_DIR"; exit 1; }

SERVICES=$(docker compose ps -aq)
if [ -z "$SERVICES" ]; then
  echo "錯誤：未找到任何服務"
  exit 1
fi

# 停止所有容器以確保一致性
echo "停止 Docker Compose 服務..."
docker compose stop || { echo "停止容器失敗"; exit 1; }

echo "===========================================" >> "$METADATA"
echo "開始備份容器資料" >> "$METADATA"

# 收集所有 volumes 和 binds
declare -A ALL_VOLUMES
declare -A ALL_BINDS

# 遍歷每個服務容器收集 mounts
for CONTAINER_ID in $SERVICES; do
  if [ -n "$CONTAINER_ID" ]; then
    CONTAINER_NAME=$(docker inspect --format '{{.Name}}' "$CONTAINER_ID" 2>/dev/null | sed 's/^\///')
  else
    continue
  fi

  if [ -z "$CONTAINER_NAME" ]; then
    echo "警告：容器 $CONTAINER_ID 無法獲取名稱，跳過" >> "$METADATA"
    continue
  fi

  echo "分析容器: $CONTAINER_NAME" >> "$METADATA"
  
  # 2. 備份所有 image
  echo "===========================================" >> "$METADATA"
  echo "開始備份 images (push to registry)" >> "$METADATA"
  echo "開始備份 Images (push to registry)..."

  VERSION="${TIMESTAMP}"
  docker commit "$CONTAINER_NAME" "localhost:5000/${CONTAINER_NAME}:$VERSION" || { echo "提交 $CONTAINER_NAME 失敗"; exit 1; }
  docker push "localhost:5000/${CONTAINER_NAME}:$VERSION" || { echo "上傳 $CONTAINER_NAME 到 Registry 失敗"; exit 1; }
  echo "$CONTAINER_NAME image: localhost:5000/${CONTAINER_NAME}:$VERSION" >> "$METADATA"
  # 刪除本地容器所對應的 image（例如 commit 後的那個）
  IMAGE_ID=$(docker images -q "$CONTAINER_NAME")
  if [ -n "$IMAGE_ID" ]; then
    docker rmi "$IMAGE_ID"
  fi

  # 刪除 registry 上的 image
  REGISTRY_IMAGE="localhost:5000/${CONTAINER_NAME}:$VERSION"
  if docker images "$REGISTRY_IMAGE" | grep -q "$VERSION"; then
    docker rmi "$REGISTRY_IMAGE"
  fi

  # 收集 volumes
  VOLUME_NAMES=$(docker inspect "$CONTAINER_NAME" --format '{{range .Mounts}}{{if eq .Type "volume"}}{{.Name}}{{"\n"}}{{end}}{{end}}')
  for VOLUME_NAME in $VOLUME_NAMES; do
    if [ -n "$VOLUME_NAME" ]; then
      ALL_VOLUMES["$VOLUME_NAME"]="$DOCKER_DIR/volumes/$VOLUME_NAME/_data"
      echo "發現 volume: $VOLUME_NAME" >> "$METADATA"
    fi
  done

  # 收集 bind mounts（排除專案資料夾內的）
  BIND_PATHS=$(docker inspect "$CONTAINER_NAME" --format '{{range .Mounts}}{{if eq .Type "bind"}}{{.Source}}{{"\n"}}{{end}}{{end}}')
  for BIND_PATH in $BIND_PATHS; do
    if [ -d "$BIND_PATH" ] && ! is_path_in_project "$BIND_PATH"; then
      ENCODED_NAME=$(echo "$BIND_PATH" | base64 | tr -d '=' | tr '/+' '_-')
      ALL_BINDS["$ENCODED_NAME"]="$BIND_PATH"
      echo "發現 bind mount: $BIND_PATH -> $ENCODED_NAME" >> "$METADATA"
    elif is_path_in_project "$BIND_PATH"; then
      echo "跳過專案內 bind mount: $BIND_PATH" >> "$METADATA"
    fi
  done
done




# 3. 備份所有 volumes
echo "===========================================" >> "$METADATA"
echo "開始備份 Volumes" >> "$METADATA"
echo "開始備份 Docker Volumes..."

for VOLUME_NAME in "${!ALL_VOLUMES[@]}"; do
  VOLUME_PATH="${ALL_VOLUMES[$VOLUME_NAME]}"
  BACKUP_FILE="$VOLUMES_BACKUP_DIR/$VOLUME_NAME"
  
  if [ -d "$VOLUME_PATH" ]; then
    perform_btrfs_backup "$VOLUME_PATH" "$BACKUP_FILE" ".btrfs.gz" "vol_${VOLUME_NAME}" "Volume $VOLUME_NAME"
  else
    echo "警告：Volume 路徑 $VOLUME_PATH 不存在，跳過" >> "$METADATA"
  fi
done

# 4. 備份所有 bind mounts
echo "===========================================" >> "$METADATA"
echo "開始備份 Bind Mounts" >> "$METADATA"
echo "開始備份 Bind Mounts..."

for ENCODED_NAME in "${!ALL_BINDS[@]}"; do
  BIND_PATH="${ALL_BINDS[$ENCODED_NAME]}"
  BACKUP_FILE="$BINDS_BACKUP_DIR/$ENCODED_NAME"
  
  if [ -d "$BIND_PATH" ]; then
    perform_btrfs_backup "$BIND_PATH" "$BACKUP_FILE" ".btrfs.gz" "bind_${ENCODED_NAME}" "Bind mount $BIND_PATH"
  else
    echo "警告：Bind mount 路徑 $BIND_PATH 不存在，跳過" >> "$METADATA"
  fi
done

# 重啟服務
echo "重新啟動 Docker Compose 服務..."
docker compose start || { echo "重啟容器失敗"; exit 1; }

echo "===========================================" >> "$METADATA"
echo "備份完成時間: $(date)" >> "$METADATA"

echo "備份完成！"
echo "備份位置: $BACKUP_BASE"
echo "- 專案資料夾: $PROJECT_BACKUP_DIR/"
echo "- Docker Volumes: $VOLUMES_BACKUP_DIR/"
echo "- Bind Mounts: $BINDS_BACKUP_DIR/"
echo "- 詳細資訊: $METADATA"

exit 0
