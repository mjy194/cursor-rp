#!/bin/bash

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"


APPIMAGE_PATH=""
OUTPUT_DIR="."
SILENT=false
FORCE=false
PATCH=false
RESTORE=false
SKIP_HOSTS=false
APPIMAGETOOL_PATH="$BASE_DIR/appimagetool"
APPIMAGETOOL_DOWNLOADING="$SCRIPT_DIR/appimagetool_downloading"
MODIFIER_PATH=""
SUDO="sudo "
MODIFIER_EXTRA_PARAMS=""

detect_system_lang() {
    local lang_var=${LANGUAGE:-${LC_ALL:-${LC_MESSAGES:-$LANG}}}
    local lang_code=$(echo "$lang_var" | cut -d'_' -f1 | cut -d'.' -f1 | tr '[:upper:]' '[:lower:]')

    case "$lang_code" in
        zh*) echo "zh" ;;
        en*) echo "en" ;;
        *)   echo "en" ;;
    esac
}

LANG_CODE=${LANG_CODE:-$(detect_system_lang)}

show_help() {
    if [ LANG_CODE = "zh" ]; then
        echo "用法: $0 [选项]"
        echo "选项:"
        echo "  -h, --help                  显示帮助信息"
        echo "  -l, --lang CODE             设置语言 (zh/en)"
        echo "  -a, --appimage <PATH>       指定 AppImage 路径"
        echo "  --patch                     执行修补操作"
        echo "  --restore                   执行恢复操作"
        echo "  --skip-hosts                跳过 modifier的hosts 文件操作"
        echo ""
        echo "注意: --patch 和 --restore 必须指定一个"
    else
        echo "Usage: $0 [options]"
        echo "Options:"
        echo "  -h, --help                  Show this message"
        echo "  -l, --lang CODE             Set language (zh/en)"
        echo "  -a, --appimage <PATH>       Cursor AppImage path"
        echo "  --patch                     Apply patch"
        echo "  --restore                   Restore original"
        echo "  --skip-hosts                Skip modify hosts file pass to modifier"
        echo ""
        echo "Note: Either --patch or --restore must be specified"
    fi
}

show_info() {
    if [ "$LANG_CODE" = "zh" ]; then
        echo "当前配置:"
        echo "  语言(Lang): $LANG_CODE"
        echo "  AppImage路径: ${APPIMAGE_PATH:-未设置}"
        echo "  操作模式: $([ "$PATCH" = "true" ] && echo "修补模式" || echo "恢复模式")"
        echo "  跳过hosts修改: $([ "$SKIP_HOSTS" = "true" ] && echo "是" || echo "否")"
    else
        echo "Current Configuration:"
        echo "  Language: $LANG_CODE"
        echo "  AppImage Path: ${APPIMAGE_PATH:-Not set}"
        echo "  Operation Mode: $([ "$PATCH" = "true" ] && echo "Patch" || echo "Restore")"
        echo "  Skip Hosts Modification: $([ "$SKIP_HOSTS" = "true" ] && echo "Yes" || echo "No")"
    fi
    echo ""
    echo ""
}

init_lang() {
    if [ "$LANG_CODE" == "en" ]; then
        MSG_ERROR_NOT_FOUND="Error: Cursor AppImage not found"
        MSG_ERROR_INVALID_MODE="Error: Invalid mode. Use '--patch' or '--restore'."
        MSG_ERROR_MODE_CONFLICT="Error: Conflicting options - please use either --patch or --restore, not both"
        MSG_PATCHING="Patching Cursor AppImage..."
        MSG_RESTORING="Restoring Cursor AppImage..."
        MSG_UNPACKING="Unpacking AppImage..."
        MSG_UNPACKED_TO="AppImage unpacked ->"
        MSG_PATCH_WITH_MODIFIER="Patch with modifier"
        MSG_PATCHING_WITH_MODIFIER="Patching with modifier..."
        MSG_ERROR_MODIFIER_FAILED="Error: modifier failed"
        MSG_REPACKING="Repacking AppImage..."
        MSG_REPACK_FAILED="Failed to repack AppImage"
        MSG_REPACK_SUCCESS="AppImage repacked, overwrite"
        MSG_REMOVING_TEMP_DIR="Removed temporary directory"
        MSG_FOUND_APPIMAGE="Found AppImage:"
        MSG_COPYING_APPIMAGE="Copying AppImage to current directory..."
        MSG_FAILED_UNPACK="Failed to unpack AppImage"
        MSG_APPIMAGETOOL_NOT_FOUND="appimagetool not found"
        MSG_DOWNLOAD_PROMPT="Download appimagetool? (Y/n):"
        MSG_DOWNLOADING="Downloading appimagetool..."
        MSG_DOWNLOAD_FAILED="Download failed. You can manually download and save it to"
        MSG_DOWNLOAD_LINK="Link:"
        MSG_APPIMAGETOOL_DOWNLOADED="Appimagetool downloaded"
        MSG_MANUAL_DOWNLOAD="Please download appimagetool and put it to"
        MSG_TO_CONTINUE="to continue"
        MSG_WGET_CURL_NOT_FOUND="Error: Neither wget nor curl is installed. Please install one of them first."
        MSG_RESTORING_COMPLETE="Restoring complete!"
        MSG_PATCHING_COMPLETE="Patching complete!"
    else
        MSG_ERROR_NOT_FOUND="错误：未找到 Cursor AppImage"
        MSG_ERROR_INVALID_MODE="错误：必须指定 --patch 或 --restore"
        MSG_ERROR_MODE_CONFLICT="错误：--patch 和 --restore 不能同时使用"
        MSG_PATCHING="正在修补 Cursor AppImage..."
        MSG_RESTORING="正在恢复 Cursor AppImage..."
        MSG_UNPACKING="正在解压 AppImage..."
        MSG_UNPACKED_TO="AppImage 已解压 ->"
        MSG_PATCH_WITH_MODIFIER="使用 modifier 修补"
        MSG_PATCHING_WITH_MODIFIER="正在使用 modifier 修补..."
        MSG_ERROR_MODIFIER_FAILED="错误：modifier 执行失败"
        MSG_REPACKING="正在重新打包 AppImage..."
        MSG_REPACK_FAILED="重新打包 AppImage 失败"
        MSG_REPACK_SUCCESS="AppImage 已重新打包，覆盖"
        MSG_REMOVING_TEMP_DIR="已移除临时目录"
        MSG_FOUND_APPIMAGE="找到 AppImage："
        MSG_COPYING_APPIMAGE="正在复制 AppImage 到当前目录..."
        MSG_FAILED_UNPACK="解压 AppImage 失败"
        MSG_APPIMAGETOOL_NOT_FOUND="未找到 appimagetool"
        MSG_DOWNLOAD_PROMPT="下载 appimagetool？(Y/n)："
        MSG_DOWNLOADING="正在下载 appimagetool..."
        MSG_DOWNLOAD_FAILED="下载失败。您可以手动下载并保存到"
        MSG_DOWNLOAD_LINK="链接："
        MSG_APPIMAGETOOL_DOWNLOADED="appimagetool 已下载"
        MSG_MANUAL_DOWNLOAD="请下载 appimagetool 并将其放置到"
        MSG_TO_CONTINUE="以继续"
        MSG_WGET_CURL_NOT_FOUND="错误：未安装 wget 或 curl。请先安装其中一个。"
        MSG_RESTORING_COMPLETE="恢复完成！"
        MSG_PATCHING_COMPLETE="修补完成！"
    fi

}

parse_params() {
    options=$(getopt -o hl:a:o:sf --long help,lang:,appimage:,patch,restore,skip-hosts -n 'cursor-rp-linux.sh' -- "$@")
    if [ $? -ne 0 ]; then
        echo "错误的选项" >&2
        exit 1
    fi

    eval set -- "$options"

    while true; do
        case "$1" in
            -h|--help)
                show_help
                exit 1
                ;;
            -l|--lang)
                LANG_CODE="$2"
                shift 2
                ;;
            -a|--appimage)
                APPIMAGE_PATH="$2"
                shift 2
                ;;
            --patch)
                PATCH=true
                shift
                ;;
            --restore)
                RESTORE=true
                shift
                ;;
            --skip-hosts)
                SKIP_HOSTS=true
                shift
                ;;
            --)
                shift
                break
                ;;
            *)
                show_help
                exit 1
                ;;
        esac
    done
    
    init_lang

    if ! $PATCH && ! $RESTORE; then
        echo $MSG_ERROR_INVALID_MODE
        exit 1
    elif $PATCH && $RESTORE; then
        echo $MSG_ERROR_MODE_CONFLICT
        exit 1
    fi

    if [ -z "$APPIMAGE_PATH" ]; then
        echo $MSG_ERROR_NOT_FOUND
        exit 1
    fi
    
    if [ ! -f $APPIMAGE_PATH ]; then
        echo "$MSG_ERROR_NOT_FOUND: ($APPIMAGE_PATH)"
        exit 1
    fi

    show_info
}

prepare() {
    MODIFIER_PATH="$BASE_DIR/modifier"
    if [ ! -f "$MODIFIER_PATH" ]; then
    echo "$MSG_ERROR_MODIFIER_NOT_FOUND $MODIFIER_PATH"
    exit 1
    fi

    if [ -f "$APPIMAGETOOL_DOWNLOADING" ]; then
        rm -f "$APPIMAGETOOL_DOWNLOADING"
    fi

    if [ ! -f "$APPIMAGETOOL_PATH" ]; then
    if command -v appimagetool &> /dev/null; then
        APPIMAGETOOL_PATH="appimagetool"
    else
      echo "$MSG_APPIMAGETOOL_NOT_FOUND"
      read -p "$MSG_DOWNLOAD_PROMPT " -r DOWNLOAD
      DOWNLOAD=${DOWNLOAD,,} # 转换为小写

      if [[ ! "$DOWNLOAD" =~ ^(n|no)$ ]]; then
          echo "$MSG_DOWNLOADING"
          download_file "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage" "$APPIMAGETOOL_DOWNLOADING"

          # 检查下载是否成功
          if [ $? -ne 0 ]; then
              echo "$MSG_DOWNLOAD_FAILED $APPIMAGETOOL_PATH"
              echo "$MSG_DOWNLOAD_LINK https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
              rm -f "$APPIMAGETOOL_DOWNLOADING"
              exit 1
          fi

          chmod +x "$APPIMAGETOOL_DOWNLOADING"
          mv "$APPIMAGETOOL_DOWNLOADING" "$APPIMAGETOOL_PATH"
          echo "$MSG_APPIMAGETOOL_DOWNLOADED"
      else
          echo "$MSG_MANUAL_DOWNLOAD $APPIMAGETOOL_PATH $MSG_TO_CONTINUE"
          echo "$MSG_DOWNLOAD_LINK https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
          exit 1
      fi
    fi
  fi
}

process_appimage() {
    local mode="patch"
    if $PATCH; then
        echo "$MSG_PATCHING"
    else
        echo "$MSG_RESTORING"
        mode="restore"
    fi

    echo "$MSG_FOUND_APPIMAGE $APPIMAGE_PATH"
    
    if [ "$(dirname "$APPIMAGE_PATH")" != "$BASE_DIR" ]; then
        echo "$MSG_COPYING_APPIMAGE"
        cp -f "$APPIMAGE_PATH" "$BASE_DIR"
        APPIMAGE_PATH="$BASE_DIR/$(basename "$APPIMAGE_PATH")"
    fi

    
    # Unpacking
    echo "$MSG_UNPACKING"
    chmod +x "$APPIMAGE_PATH"
    "$APPIMAGE_PATH" --appimage-extract > /dev/null 2>&1

    if [ $? -ne 0 ]; then
        echo "$MSG_FAILED_UNPACK"
        exit 1
    fi

    echo "$MSG_UNPACKED_TO squashfs-root"

    # Do modifier
    echo "$MSG_PATCHING_WITH_MODIFIER"
    if $SKIP_HOSTS; then
        SUDO=""
        MODIFIER_EXTRA_PARAMS="--skip-hosts"
    fi
    echo $SUDO "$MODIFIER_PATH" --cursor-path "$BASE_DIR/squashfs-root/usr/share/cursor/resources/app" --port 2999 --suffix .local local $MODIFIER_EXTRA_PARAMS
    $SUDO "$MODIFIER_PATH" --cursor-path "$BASE_DIR/squashfs-root/usr/share/cursor/resources/app" --port 2999 --suffix .local local $MODIFIER_EXTRA_PARAMS

    if [ $? -ne 0 ]; then
        echo "$MSG_ERROR_MODIFIER_FAILED"
        exit 1
    fi


    # Repacking
    echo "$MSG_REPACKING"
    "$APPIMAGETOOL_PATH" squashfs-root "$APPIMAGE_PATH"

    if [ $? -ne 0 ]; then
        echo "$MSG_REPACK_FAILED"
        exit 1
    fi

    echo "$MSG_REPACK_SUCCESS $APPIMAGE_PATH"

    # cleanup
    rm -rf squashfs-root
    echo "$MSG_REMOVING_TEMP_DIR squashfs-root"

    if [ "$mode" == "patch" ]; then
        echo "$MSG_PATCHING_COMPLETE"
    else
        echo "$MSG_RESTORING_COMPLETE"
    fi
    
    exit 0
}

main() {
    parse_params $@
    prepare
    process_appimage
}

main $@