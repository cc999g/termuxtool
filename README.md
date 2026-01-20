#!/data/data/com.termux/files/usr/bin/bash

# 清屏（放在脚本最前端）
clear

# ==============================================
#   ██╗   ██╗ ██████╗
#   ╚██╗ ██╔╝██╔════╝
#    ╚████╔╝ ██║     
#     ╚██╔╝  ██║     
#      ██║   ╚██████╗
#      ╚═╝    ╚═════╝
#
#  Termux 增强版环境配置脚本 v1.0
#  功能：IP检测、代理自动切换、Git镜像管理、延迟测试、交互式配置、GitHub PAT配置
#  新增：Git配置提示、批量安装工具、缓存清理、配置导入导出、脚本安装卸载、自动镜像选择
# ==============================================

# -------------------------- 初始化配置 --------------------------
# 调整 Termux 应用内滚动缓冲区到10000
export TERMUX_SCROLLBACK=10000
export HOSTNAME=xiaomi6

# -------------------------- 版本信息 --------------------------
SCRIPT_VERSION="1.0"
SCRIPT_UPDATE_URL="https://raw.githubusercontent.com/cc999g/termuxtool/refs/heads/main/version.txt"
SCRIPT_SOURCE_URL="https://raw.githubusercontent.com/cc999g/termuxtool/refs/heads/main/termuxtool.sh"
CONFIG_FILE="$HOME/.termuxtool_config"
LOG_FILE="$HOME/.termuxtool.log"
BACKUP_DIR="$HOME/.termuxtool_backups"

# -------------------------- 颜色和样式定义 --------------------------
COLOR_RESET="\033[0m"
COLOR_BLACK="\033[30m"
COLOR_RED="\033[31m"
COLOR_GREEN="\033[32m"
COLOR_YELLOW="\033[33m"
COLOR_BLUE="\033[34m"
COLOR_PURPLE="\033[35m"
COLOR_CYAN="\033[36m"
COLOR_WHITE="\033[37m"
COLOR_BOLD="\033[1m"
COLOR_UNDERLINE="\033[4m"

STYLE_SUCCESS="${COLOR_GREEN}${COLOR_BOLD}"
STYLE_ERROR="${COLOR_RED}${COLOR_BOLD}"
STYLE_WARNING="${COLOR_YELLOW}${COLOR_BOLD}"
STYLE_INFO="${COLOR_CYAN}${COLOR_BOLD}"
STYLE_TITLE="${COLOR_PURPLE}${COLOR_BOLD}"
STYLE_HIGHLIGHT="${COLOR_WHITE}${COLOR_BOLD}"
STYLE_DIM="${COLOR_WHITE}"

# -------------------------- 配置参数区 --------------------------
# 加载保存的配置
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        print_status info "加载保存的配置"
    fi
}

# 保存配置
save_config() {
    cat > "$CONFIG_FILE" << EOF
# Termux 增强版配置
PROXY_PROTOCOL="$PROXY_PROTOCOL"
PROXY_HOST="$PROXY_HOST"
PROXY_PORT="$PROXY_PORT"
PROXY_USER="$PROXY_USER"
PROXY_PASS="$PROXY_PASS"
ENABLE_BOOT_CHECK="$ENABLE_BOOT_CHECK"
ENABLE_PROGRESS_INDICATOR="$ENABLE_PROGRESS_INDICATOR"
CONFIG_TIMEOUT="$CONFIG_TIMEOUT"
DELAY_THRESHOLD="$DELAY_THRESHOLD"
EOF
    chmod 600 "$CONFIG_FILE"
}

# 默认配置
PROXY_PROTOCOL=${PROXY_PROTOCOL:-"http"}
PROXY_HOST=${PROXY_HOST:-"127.0.0.1"}
PROXY_PORT=${PROXY_PORT:-"7890"}
PROXY_USER=${PROXY_USER:-""}
PROXY_PASS=${PROXY_PASS:-""}
ENABLE_BOOT_CHECK=${ENABLE_BOOT_CHECK:-"true"}
ENABLE_PROGRESS_INDICATOR=${ENABLE_PROGRESS_INDICATOR:-"true"}
CONFIG_TIMEOUT=${CONFIG_TIMEOUT:-10}
DELAY_THRESHOLD=${DELAY_THRESHOLD:-500}

# 根据配置生成代理URL
if [ -n "$PROXY_USER" ] && [ -n "$PROXY_PASS" ]; then
    PROXY_HTTP="http://${PROXY_USER}:${PROXY_PASS}@${PROXY_HOST}:${PROXY_PORT}"
    PROXY_SOCKS5="socks5://${PROXY_USER}:${PROXY_PASS}@${PROXY_HOST}:${PROXY_PORT}"
    PROXY_BASIC="${PROXY_USER}:${PROXY_PASS}@${PROXY_HOST}:${PROXY_PORT}"
else
    PROXY_HTTP="http://${PROXY_HOST}:${PROXY_PORT}"
    PROXY_SOCKS5="socks5://${PROXY_HOST}:${PROXY_PORT}"
    PROXY_BASIC="${PROXY_HOST}:${PROXY_PORT}"
fi

# 连通性检测地址
CHECK_URL_GOOGLE="https://www.google.com"
CHECK_URL_BAIDU="https://www.baidu.com"
CHECK_URL_GITHUB="https://github.com"
TEST_URL="www.baidu.com"

# 延迟测试参数
DELAY_TEST_COUNT=5

# IP检测接口列表
IP_CHECK_API=(
    "https://api.ipify.org"
    "https://icanhazip.com"
    "https://myip.ipip.net"
)

# IP归属地查询接口
LOC_CHECK_API=(
    "http://ip-api.com/json/%IP%?fields=country,city,regionName,isp"
    "https://ipinfo.io/%IP%/json"
    "https://ipapi.co/%IP%/json/"
)

# Git镜像源列表
GIT_MIRROR=(
    "https://gitclone.com/github.com/"
    "https://mirror.ghproxy.com/https://github.com/"
    "https://ghproxy.com/https://github.com/"
    "https://github.com/"
)
CURRENT_MIRROR=0

# GitHub配置
GITHUB_PAT_FILE="$HOME/.github_pat"
GITHUB_CREDENTIALS_FILE="$HOME/.git-credentials"
GITHUB_USER_FILE="$HOME/.github_user"

# -------------------------- 日志函数 --------------------------
log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# -------------------------- 进度指示器函数 --------------------------
show_progress() {
    if [ "$ENABLE_PROGRESS_INDICATOR" != "true" ]; then
        return
    fi
    
    local message=$1
    local pid=$2
    local delay=0.1
    local spinstr='⣾⣽⣻⢿⡿⣟⣯⣷'
    
    printf "${COLOR_CYAN}${message}${COLOR_RESET} "
    
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        for i in $(seq 0 7); do
            printf "\b${spinstr:$i:1}"
            sleep $delay
        done
    done
    printf "\b✅\n"
}

start_progress() {
    if [ "$ENABLE_PROGRESS_INDICATOR" != "true" ]; then
        echo -e "${COLOR_CYAN}$1${COLOR_RESET}"
        return
    fi
    
    local message=$1
    printf "${COLOR_CYAN}${message}${COLOR_RESET} "
}

end_progress() {
    if [ "$ENABLE_PROGRESS_INDICATOR" != "true" ]; then
        return
    fi
    printf "\b✅\n"
}

# -------------------------- 显示美化函数 --------------------------
print_section() {
    echo -e "\n${COLOR_BLUE}════════════════════════════════════════════════════════════${COLOR_RESET}"
    echo -e "${COLOR_PURPLE}$1${COLOR_RESET}"
    echo -e "${COLOR_BLUE}════════════════════════════════════════════════════════════${COLOR_RESET}"
}

print_subsection() {
    echo -e "\n${COLOR_CYAN}── $1 ──${COLOR_RESET}"
}

print_status() {
    local status=$1
    local message=$2
    
    # 记录到日志
    log_message "$status" "$message"
    
    case $status in
        success) echo -e "${STYLE_SUCCESS}✅ $message${COLOR_RESET}" ;;
        error) echo -e "${STYLE_ERROR}❌ $message${COLOR_RESET}" ;;
        warning) echo -e "${STYLE_WARNING}⚠️  $message${COLOR_RESET}" ;;
        info) echo -e "${STYLE_INFO}ℹ️  $message${COLOR_RESET}" ;;
        *) echo -e "$message" ;;
    esac
}

print_list_item() {
    echo -e "  ${COLOR_GREEN}•${COLOR_RESET} $1"
}

print_table_row() {
    printf "  ${COLOR_CYAN}%-15s${COLOR_RESET} : %s\n" "$1" "$2"
}

# -------------------------- 显示欢迎语 --------------------------
show_welcome() {
    echo -e "${COLOR_PURPLE}"
    echo "   ██╗   ██╗ ██████╗"
    echo "   ╚██╗ ██╔╝██╔════╝"
    echo "    ╚████╔╝ ██║     "
    echo "     ╚██╔╝  ██║     "
    echo "      ██║   ╚██████╗"
    echo "      ╚═╝    ╚═════╝"
    echo -e "${COLOR_RESET}"
    echo -e "          📌 Termux 增强版环境配置脚本 v${SCRIPT_VERSION}"
    echo -e "          📌 功能：IP检测、代理切换、Git镜像、GitHub PAT"
    echo -e "          📌 新增：Termux命令大全、镜像源配置、系统信息\n"
}

# -------------------------- 显示快捷命令提示 --------------------------
show_quick_commands() {
    print_section "🚀 快捷命令提示"
    
    echo -e "${COLOR_CYAN}🌐 代理相关命令:${COLOR_RESET}"
    print_list_item "proxy-on - 开启代理"
    print_list_item "proxy-off - 关闭代理"
    print_list_item "proxy-check - 检测代理"
    print_list_item "proxy-set - 配置代理"
    print_list_item "proxy-test - 测试代理"
    print_list_item "delay-compare - 延迟对比"
    
    echo -e "\n${COLOR_CYAN}🔄 网络检测命令:${COLOR_RESET}"
    print_list_item "net-check - 网络连通性检测"
    print_list_item "speed-test - Git镜像速度测试"
    
    echo -e "\n${COLOR_CYAN}📦 Git镜像命令:${COLOR_RESET}"
    print_list_item "git-mirror-switch - 切换Git镜像"
    print_list_item "git-mirror-check - 查看Git镜像"
    print_list_item "git-mirror-off - 关闭Git镜像"
    print_list_item "git-config - 配置Git镜像"
    print_list_item "git-speed-test - 测试镜像速度"
    
    echo -e "\n${COLOR_CYAN}🐙 GitHub命令:${COLOR_RESET}"
    print_list_item "github-pat-setup - 配置GitHub PAT"
    print_list_item "github-pat-remove - 移除GitHub PAT"
    print_list_item "github-status - 查看GitHub状态"
    
    echo -e "\n${COLOR_CYAN}🛠️ 系统命令:${COLOR_RESET}"
    print_list_item "termux-commands - 显示Termux命令大全"
    print_list_item "termux-mirror - 配置Termux镜像源"
    print_list_item "toggle-mirror - 开关Git镜像"
    print_list_item "check-mirror - 检查Git镜像配置"
    print_list_item "script-update - 检查脚本更新"
    print_list_item "script-version - 显示脚本版本"
    print_list_item "system-info - 显示系统信息"
    
    echo -e "\n${COLOR_YELLOW}💡 提示: 输入 'help' 显示此帮助信息${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}💡 提示: 命令提示符中 'P 🟢' 表示代理开启，'M 🟢' 表示镜像开启${COLOR_RESET}"
}

# -------------------------- 依赖检测函数 --------------------------
check_dependencies() {
    local dependencies=("curl" "bc" "awk" "git" "free" "df" "date" "grep" "sed" "cut")
    local missing=()

    for dep in "${dependencies[@]}"; do
        if ! command -v $dep &> /dev/null; then
            missing+=($dep)
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        print_status error "缺失依赖工具: ${missing[*]}"
        echo -e "${COLOR_GREEN}📦 一键安装命令: pkg install ${missing[*]} -y${COLOR_RESET}"
        read -p "是否立即安装? (y/N): " install_choice
        if [[ "$install_choice" =~ ^[Yy]$ ]]; then
            pkg install "${missing[@]}" -y
            if [ $? -eq 0 ]; then
                print_status success "依赖安装完成"
            else
                print_status error "依赖安装失败，请手动安装"
                exit 1
            fi
        else
            print_status info "请手动安装依赖后重新运行脚本"
            exit 1
        fi
    fi
}

# -------------------------- Git配置提示和状态显示 --------------------------
show_git_config() {
    print_section "🔧 Git 配置状态"
    
    # Git用户信息
    local git_user=$(git config --global user.name 2>/dev/null || echo "未设置")
    local git_email=$(git config --global user.email 2>/dev/null || echo "未设置")
    local git_editor=$(git config --global core.editor 2>/dev/null || echo "默认")
    local git_autocrlf=$(git config --global core.autocrlf 2>/dev/null || echo "未设置")
    local git_safecrlf=$(git config --global core.safecrlf 2>/dev/null || echo "未设置")
    
    echo -e "${COLOR_CYAN}📝 Git 用户配置:${COLOR_RESET}"
    print_table_row "用户名" "$git_user"
    print_table_row "邮箱" "$git_email"
    print_table_row "编辑器" "$git_editor"
    print_table_row "换行符处理" "$git_autocrlf"
    print_table_row "安全换行符" "$git_safecrlf"
    
    # Git别名
    local git_aliases=$(git config --global --get-regexp alias | head -10 2>/dev/null || echo "无别名配置")
    if [ "$git_aliases" != "无别名配置" ]; then
        echo -e "\n${COLOR_CYAN}📋 Git 别名配置:${COLOR_RESET}"
        echo "$git_aliases" | while read alias; do
            echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} $alias"
        done
    else
        echo -e "\n${COLOR_CYAN}📋 Git 别名配置:${COLOR_RESET}"
        print_table_row "状态" "无别名配置"
    fi
    
    # Git镜像配置
    local git_mirror=$(git config --global --get-regexp url 2>/dev/null | head -5 || echo "无镜像配置")
    echo -e "\n${COLOR_CYAN}🔄 Git 镜像配置:${COLOR_RESET}"
    if [ "$git_mirror" != "无镜像配置" ]; then
        echo "$git_mirror" | while read mirror; do
            echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} $mirror"
        done
    else
        print_table_row "状态" "使用官方源"
    fi
    
    # Git代理配置
    local git_http_proxy=$(git config --global http.proxy 2>/dev/null || echo "未设置")
    local git_https_proxy=$(git config --global https.proxy 2>/dev/null || echo "未设置")
    echo -e "\n${COLOR_CYAN}🌐 Git 代理配置:${COLOR_RESET}"
    print_table_row "HTTP代理" "${git_http_proxy:-未设置}"
    print_table_row "HTTPS代理" "${git_https_proxy:-未设置}"
    
    # Git凭据存储
    local git_credential=$(git config --global credential.helper 2>/dev/null || echo "未设置")
    echo -e "\n${COLOR_CYAN}🔐 Git 凭据存储:${COLOR_RESET}"
    print_table_row "凭据助手" "$git_credential"
    
    # 提示信息
    echo -e "\n${COLOR_YELLOW}💡 Git 配置提示:${COLOR_RESET}"
    print_list_item "建议设置用户名和邮箱: git config --global user.name 'Your Name'"
    print_list_item "建议设置编辑器: git config --global core.editor vim"
    print_list_item "Windows用户设置换行符: git config --global core.autocrlf true"
    print_list_item "Linux/Mac用户设置换行符: git config --global core.autocrlf input"
    print_list_item "设置别名提高效率: git config --global alias.st status"
    print_list_item "设置凭据存储避免重复输入密码: git config --global credential.helper store"
}

configure_git_basic() {
    print_section "⚙️ 配置 Git 基本信息"
    
    echo -e "${COLOR_CYAN}设置 Git 用户信息 (必填):${COLOR_RESET}"
    read -p "请输入用户名: " git_name
    read -p "请输入邮箱地址: " git_email
    
    if [ -z "$git_name" ] || [ -z "$git_email" ]; then
        print_status error "用户名和邮箱不能为空"
        return 1
    fi
    
    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
    
    echo -e "\n${COLOR_CYAN}选择换行符处理方式:${COLOR_RESET}"
    print_list_item "1) Windows风格 (推荐给Windows用户)"
    print_list_item "2) Unix风格 (推荐给Linux/Mac用户)"
    print_list_item "3) 不设置"
    read -p "请选择 [1-3]: " crlf_choice
    
    case $crlf_choice in
        1)
            git config --global core.autocrlf true
            git config --global core.safecrlf warn
            print_status success "已设置为Windows换行符风格"
            ;;
        2)
            git config --global core.autocrlf input
            git config --global core.safecrlf warn
            print_status success "已设置为Unix换行符风格"
            ;;
        3)
            print_status info "跳过换行符设置"
            ;;
    esac
    
    echo -e "\n${COLOR_CYAN}是否设置常用别名?${COLOR_RESET}"
    read -p "选择 (y/N): " alias_choice
    
    if [[ "$alias_choice" =~ ^[Yy]$ ]]; then
        git config --global alias.st "status"
        git config --global alias.ci "commit"
        git config --global alias.co "checkout"
        git config --global alias.br "branch"
        git config --global alias.lg "log --oneline --graph --all"
        git config --global alias.last "log -1 HEAD"
        git config --global alias.unstage "reset HEAD --"
        git config --global alias.undo "reset --soft HEAD^"
        print_status success "已设置常用Git别名"
    fi
    
    print_status success "Git基本配置完成"
    show_git_config
}

# -------------------------- 系统信息显示函数 --------------------------
show_system_info() {
    print_section "💻 系统信息汇总"
    
    echo -e "${COLOR_CYAN}📋 基础信息:${COLOR_RESET}"
    print_table_row "日期时间" "$(date '+%Y-%m-%d %H:%M:%S')"
    print_table_row "主机名" "$HOSTNAME"
    print_table_row "当前目录" "$(pwd)"
    print_table_row "脚本版本" "$SCRIPT_VERSION"
    
    echo -e "\n${COLOR_CYAN}💾 系统状态:${COLOR_RESET}"
    print_table_row "内存占用" "$(free -h | grep Mem | awk '{print $3 "/" $2}')"
    print_table_row "存储占用" "$(df -h $HOME | grep /data | awk '{print $3 "/" $2 " (" $5 ")"}')"
    print_table_row "电池状态" "$(get_battery_info)"
    
    echo -e "\n${COLOR_CYAN}🌐 网络信息:${COLOR_RESET}"
    print_table_row "局域网IP" "$LOCAL_IP_FULL"
    print_table_row "公网IP" "$PUBLIC_IP_FULL"
    print_table_row "归属地" "${PUBLIC_LOC:-(局域网IP)}"
    
    if [ "$PROXY_STATUS" = "P 🟢" ]; then
        print_table_row "代理IP" "$PROXY_PUBLIC_IP"
        print_table_row "代理归属地" "${PROXY_PUBLIC_LOC}"
        print_table_row "直连延迟" "$(delay_alert $DIRECT_DELAY)"
        print_table_row "代理延迟" "$(delay_alert $PROXY_DELAY)"
    else
        print_table_row "直连延迟" "$(delay_alert $DIRECT_DELAY)"
        print_table_row "代理状态" "未开启"
    fi
    
    echo -e "\n${COLOR_CYAN}🔧 配置状态:${COLOR_RESET}"
    show_github_status
    check_global_mirror
}

# -------------------------- 电池信息函数 --------------------------
get_battery_info() {
    if ! command -v termux-battery-status &> /dev/null; then
        print_status warning "未安装 termux-api，请执行 pkg install termux-api 后重试"
        return 1
    fi

    local battery_data=$(termux-battery-status 2>/dev/null)
    if [ -z "$battery_data" ]; then
        print_status warning "无法获取电池数据，请检查 Termux API 权限"
        return 1
    fi

    local level=$(echo "$battery_data" | grep -oE '"percentage"[[:space:]]*:[[:space:]]*[0-9]+' | sed 's/.*://' | tr -d ' [:space:],"')
    local status=$(echo "$battery_data" | grep -oE '"status"[[:space:]]*:[[:space:]]*"[^"]+"' | sed 's/.*"://; s/"//g' | tr -d ' [:space:]')
    local plugged=$(echo "$battery_data" | grep -oE '"plugged"[[:space:]]*:[[:space:]]*"[^"]+"' | sed 's/.*"://; s/"//g' | tr -d ' [:space:]')
    local current=$(echo "$battery_data" | grep -oE '"current"[[:space:]]*:[[:space:]]*[0-9-]+' | sed 's/.*://' | tr -d ' [:space:],"')

    if [ -z "$level" ]; then
        level="未知"
    fi

    case $status in
        CHARGING) 
            case $plugged in
                PLUGGED_USB) status="🔌 USB充电" ;;
                PLUGGED_AC) status="🔌 直充" ;;
                PLUGGED_WIRELESS) status="🔌 无线" ;;
                *) status="🔌 充电中" ;;
            esac ;;
        DISCHARGING) status="🔋 放电中" ;;
        FULL) status="✅ 已充满" ;;
        NOT_CHARGING) status="🔋 未充电" ;;
        *) status="ℹ️ 未知" ;;
    esac

    if [ -z "$current" ]; then
        current="设备不支持采集"
    elif [ "$current" -gt 10000 ] || [ "$current" -lt -10000 ]; then
        current="数值异常(${current})"
    else
        current="${current}mA"
    fi

    echo "🔋 ${level}% | ${status} | ${current}"
}

# -------------------------- 批量安装常用工具 --------------------------
install_common_tools() {
    print_section "📦 批量安装常用工具"
    
    # 工具分类列表
    local basic_tools=("curl" "wget" "git" "vim" "nano" "htop" "neofetch" "tmux")
    local dev_tools=("python" "nodejs" "clang" "make" "cmake" "binutils" "pkg-config")
    local network_tools=("nmap" "net-tools" "dnsutils" "openssh" "telnet" "tcpdump")
    local utils_tools=("tree" "zip" "unzip" "p7zip" "rsync" "jq" "yq" "fzf" "bat" "ripgrep")
    local termux_tools=("termux-api" "termux-tools" "termux-services")
    
    echo -e "${COLOR_CYAN}选择要安装的工具类别:${COLOR_RESET}"
    print_list_item "1) 基础工具 (${#basic_tools[@]}个)"
    print_list_item "2) 开发工具 (${#dev_tools[@]}个)"
    print_list_item "3) 网络工具 (${#network_tools[@]}个)"
    print_list_item "4) 实用工具 (${#utils_tools[@]}个)"
    print_list_item "5) Termux专用工具 (${#termux_tools[@]}个)"
    print_list_item "6) 全部安装"
    print_list_item "0) 取消"
    
    read -p "请选择 [0-6]: " category_choice
    
    case $category_choice in
        1) selected_tools=("${basic_tools[@]}") ;;
        2) selected_tools=("${dev_tools[@]}") ;;
        3) selected_tools=("${network_tools[@]}") ;;
        4) selected_tools=("${utils_tools[@]}") ;;
        5) selected_tools=("${termux_tools[@]}") ;;
        6) 
            selected_tools=(
                "${basic_tools[@]}" 
                "${dev_tools[@]}" 
                "${network_tools[@]}" 
                "${utils_tools[@]}" 
                "${termux_tools[@]}"
            )
            ;;
        0) 
            print_status info "取消安装"
            return
            ;;
        *)
            print_status error "无效的选择"
            return 1
            ;;
    esac
    
    echo -e "\n${COLOR_YELLOW}即将安装以下工具 (共 ${#selected_tools[@]} 个):${COLOR_RESET}"
    for tool in "${selected_tools[@]}"; do
        print_list_item "$tool"
    done
    
    echo -e "\n${COLOR_YELLOW}确认安装?${COLOR_RESET}"
    read -p "选择 (y/N): " confirm_install
    
    if [[ ! "$confirm_install" =~ ^[Yy]$ ]]; then
        print_status info "取消安装"
        return
    fi
    
    # 更新包列表
    start_progress "更新包列表"
    pkg update -y > /dev/null 2>&1
    end_progress
    
    # 安装选中的工具
    local total=${#selected_tools[@]}
    local installed=0
    local failed=()
    
    echo -e "\n${COLOR_CYAN}开始安装工具...${COLOR_RESET}"
    for ((i=0; i<total; i++)); do
        local tool="${selected_tools[$i]}"
        local progress=$(( (i+1) * 100 / total ))
        
        printf "\r[%-50s] %d%% 正在安装: %-20s" \
            "$(printf '#%.0s' $(seq 1 $((progress/2))))" \
            "$progress" \
            "$tool"
        
        if pkg install "$tool" -y > /dev/null 2>&1; then
            installed=$((installed + 1))
        else
            failed+=("$tool")
        fi
    done
    printf "\n"
    
    # 显示安装结果
    if [ $installed -eq $total ]; then
        print_status success "所有工具安装成功 (${installed}/${total})"
    else
        print_status warning "部分工具安装失败 (${installed}/${total})"
        if [ ${#failed[@]} -gt 0 ]; then
            echo -e "${COLOR_RED}失败的工具: ${failed[*]}${COLOR_RESET}"
            echo -e "${COLOR_YELLOW}可以尝试手动安装: pkg install ${failed[*]} -y${COLOR_RESET}"
        fi
    fi
    
    # 显示安装的工具信息
    echo -e "\n${COLOR_CYAN}已安装工具版本信息:${COLOR_RESET}"
    for tool in "${selected_tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            local version=$("$tool" --version 2>/dev/null | head -1 | cut -d' ' -f2-3 || echo "已安装")
            print_table_row "$tool" "$version"
        fi
    done
}

# -------------------------- 自动清理缓存 --------------------------
clean_cache() {
    print_section "🧹 自动清理缓存"
    
    # 清理APT缓存
    local apt_cache_size=$(du -sh /data/data/com.termux/files/usr/var/cache/apt/archives 2>/dev/null | cut -f1 || echo "0B")
    
    echo -e "${COLOR_CYAN}检测到APT缓存大小: ${COLOR_YELLOW}${apt_cache_size}${COLOR_RESET}"
    
    # 清理TMP目录
    local tmp_size=$(du -sh /data/data/com.termux/files/usr/tmp 2>/dev/null | cut -f1 || echo "0B")
    
    echo -e "${COLOR_CYAN}检测到临时文件大小: ${COLOR_YELLOW}${tmp_size}${COLOR_RESET}"
    
    # 清理下载缓存
    local download_size=$(du -sh ~/storage/downloads 2>/dev/null | cut -f1 || echo "0B")
    
    echo -e "${COLOR_CYAN}检测到下载目录大小: ${COLOR_YELLOW}${download_size}${COLOR_RESET}"
    
    echo -e "\n${COLOR_YELLOW}请选择要清理的内容:${COLOR_RESET}"
    print_list_item "1) APT包缓存 (${apt_cache_size})"
    print_list_item "2) 临时文件 (${tmp_size})"
    print_list_item "3) 下载缓存 (${download_size})"
    print_list_item "4) 全部清理"
    print_list_item "0) 取消"
    
    read -p "请选择 [0-4]: " clean_choice
    
    local total_freed=0
    local cleaned_items=()
    
    case $clean_choice in
        1|4)
            start_progress "清理APT缓存"
            pkg clean > /dev/null 2>&1
            end_progress
            cleaned_items+=("APT缓存")
            total_freed=$((total_freed + $(echo "$apt_cache_size" | sed 's/[^0-9]*//g') * 1024))
            ;;
        2|4)
            start_progress "清理临时文件"
            rm -rf /data/data/com.termux/files/usr/tmp/* > /dev/null 2>&1
            end_progress
            cleaned_items+=("临时文件")
            total_freed=$((total_freed + $(echo "$tmp_size" | sed 's/[^0-9]*//g') * 1024))
            ;;
        3|4)
            start_progress "清理下载缓存"
            rm -rf ~/storage/downloads/* > /dev/null 2>&1
            end_progress
            cleaned_items+=("下载缓存")
            total_freed=$((total_freed + $(echo "$download_size" | sed 's/[^0-9]*//g') * 1024))
            ;;
        0)
            print_status info "取消清理"
            return
            ;;
        *)
            print_status error "无效的选择"
            return 1
            ;;
    esac
    
    if [ ${#cleaned_items[@]} -gt 0 ]; then
        print_status success "清理完成"
        echo -e "${COLOR_CYAN}已清理的项目:${COLOR_RESET}"
        for item in "${cleaned_items[@]}"; do
            echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} $item"
        done
        
        # 转换为可读大小
        local freed_kb=$total_freed
        local freed_mb=0
        local freed_gb=0
        
        if [ $freed_kb -ge 1048576 ]; then
            freed_gb=$((freed_kb / 1048576))
            freed_kb=$((freed_kb % 1048576))
            freed_mb=$((freed_kb / 1024))
            echo -e "${COLOR_CYAN}释放空间: ${COLOR_GREEN}${freed_gb}GB ${freed_mb}MB${COLOR_RESET}"
        elif [ $freed_kb -ge 1024 ]; then
            freed_mb=$((freed_kb / 1024))
            echo -e "${COLOR_CYAN}释放空间: ${COLOR_GREEN}${freed_mb}MB${COLOR_RESET}"
        else
            echo -e "${COLOR_CYAN}释放空间: ${COLOR_GREEN}${freed_kb}KB${COLOR_RESET}"
        fi
    else
        print_status info "没有选择清理项目"
    fi
    
    # 显示清理后的磁盘空间
    echo -e "\n${COLOR_CYAN}当前磁盘空间使用情况:${COLOR_RESET}"
    df -h /data | grep -v Filesystem | while read line; do
        echo -e "  ${COLOR_GREEN}📊${COLOR_RESET} $line"
    done
}

# -------------------------- 配置导入导出 --------------------------
export_config() {
    print_section "📤 导出配置"
    
    # 创建备份目录
    mkdir -p "$BACKUP_DIR"
    
    # 生成备份文件名
    local timestamp=$(date "+%Y%m%d_%H%M%S")
    local backup_file="$BACKUP_DIR/termux_config_${timestamp}.tar.gz"
    
    # 收集所有配置文件
    local config_files=(
        "$CONFIG_FILE"
        "$GITHUB_PAT_FILE"
        "$GITHUB_USER_FILE"
        "$GITHUB_CREDENTIALS_FILE"
        "$HOME/.gitconfig"
        "$HOME/.bashrc"
        "$HOME/.bash_profile"
        "$HOME/.profile"
    )
    
    # 实际存在的配置文件
    local existing_files=()
    for file in "${config_files[@]}"; do
        if [ -f "$file" ]; then
            existing_files+=("$file")
            echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} 包含: $file"
        fi
    done
    
    if [ ${#existing_files[@]} -eq 0 ]; then
        print_status warning "没有找到可导出的配置文件"
        return 1
    fi
    
    # 创建备份
    start_progress "创建配置文件备份"
    tar -czf "$backup_file" "${existing_files[@]}" 2>/dev/null
    end_progress
    
    local file_size=$(du -h "$backup_file" | cut -f1)
    print_status success "配置导出完成"
    print_table_row "备份文件" "$backup_file"
    print_table_row "文件大小" "$file_size"
    print_table_row "包含文件" "${#existing_files[@]}个"
    
    # 显示备份列表
    echo -e "\n${COLOR_CYAN}备份文件列表:${COLOR_RESET}"
    ls -lh "$BACKUP_DIR" | grep termux_config | while read line; do
        echo -e "  ${COLOR_GREEN}📁${COLOR_RESET} $line"
    done
}

import_config() {
    print_section "📥 导入配置"
    
    # 检查备份目录
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        print_status info "备份目录不存在，已创建"
    fi
    
    # 列出备份文件
    local backups=($(ls "$BACKUP_DIR"/*.tar.gz 2>/dev/null))
    
    if [ ${#backups[@]} -eq 0 ]; then
        print_status warning "没有找到备份文件"
        echo -e "${COLOR_YELLOW}请先使用 export-config 命令导出配置${COLOR_RESET}"
        return 1
    fi
    
    echo -e "${COLOR_CYAN}可用的备份文件:${COLOR_RESET}"
    for i in "${!backups[@]}"; do
        local file_name=$(basename "${backups[$i]}")
        local file_size=$(du -h "${backups[$i]}" | cut -f1)
        local file_time=$(stat -c %y "${backups[$i]}" 2>/dev/null | cut -d' ' -f1,2)
        echo -e "  ${COLOR_GREEN}$((i+1)))${COLOR_RESET} $file_name (${file_size}, ${file_time})"
    done
    
    echo -e "\n${COLOR_YELLOW}选择要导入的备份文件:${COLOR_RESET}"
    read -p "请输入编号 [1-${#backups[@]}] (0取消): " backup_choice
    
    if [ "$backup_choice" = "0" ]; then
        print_status info "取消导入"
        return
    fi
    
    if ! [[ "$backup_choice" =~ ^[0-9]+$ ]] || [ "$backup_choice" -lt 1 ] || [ "$backup_choice" -gt ${#backups[@]} ]; then
        print_status error "无效的选择"
        return 1
    fi
    
    local selected_backup="${backups[$((backup_choice-1))]}"
    local backup_name=$(basename "$selected_backup")
    
    # 显示备份内容
    echo -e "\n${COLOR_CYAN}备份文件内容预览:${COLOR_RESET}"
    tar -tzf "$selected_backup" 2>/dev/null | while read file; do
        echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} $file"
    done
    
    echo -e "\n${COLOR_YELLOW}警告: 导入配置将覆盖现有文件${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}确认导入配置?${COLOR_RESET}"
    read -p "选择 (y/N): " confirm_import
    
    if [[ ! "$confirm_import" =~ ^[Yy]$ ]]; then
        print_status info "取消导入"
        return
    fi
    
    # 备份当前配置
    start_progress "备份当前配置"
    local current_backup="$BACKUP_DIR/current_backup_$(date +%s).tar.gz"
    tar -czf "$current_backup" "$CONFIG_FILE" "$HOME/.gitconfig" 2>/dev/null
    end_progress
    
    # 解压备份文件
    start_progress "导入配置"
    tar -xzf "$selected_backup" -C / 2>/dev/null
    end_progress
    
    print_status success "配置导入完成"
    print_table_row "导入文件" "$backup_name"
    print_table_row "当前备份" "$(basename "$current_backup")"
    
    # 重新加载配置
    load_config
}

# -------------------------- 脚本安装卸载 --------------------------
install_script() {
    print_section "🔧 脚本安装"
    
    # 检查是否已安装
    local install_file="$HOME/.termux/boot/termuxtool.sh"
    local bashrc_file="$HOME/.bashrc"
    
    if [ -f "$install_file" ]; then
        print_status info "脚本已安装"
        echo -e "${COLOR_YELLOW}是否重新安装?${COLOR_RESET}"
        read -p "选择 (y/N): " reinstall_choice
        
        if [[ ! "$reinstall_choice" =~ ^[Yy]$ ]]; then
            return
        fi
    fi
    
    # 创建启动目录
    mkdir -p "$HOME/.termux/boot"
    
    # 复制脚本到启动目录
    start_progress "安装启动脚本"
    cp "$0" "$install_file"
    chmod +x "$install_file"
    end_progress
    
    # 添加到.bashrc
    if ! grep -q "termuxtool" "$bashrc_file"; then
        echo -e "\n# Termux 增强版脚本" >> "$bashrc_file"
        echo "alias tool='bash $install_file'" >> "$bashrc_file"
        echo "source $install_file" >> "$bashrc_file"
        print_status success "已添加到.bashrc"
    else
        print_status info "已存在于.bashrc"
    fi
    
    # 创建卸载脚本
    local uninstall_file="$HOME/.termux/boot/uninstall_tool.sh"
    cat > "$uninstall_file" << EOF
#!/data/data/com.termux/files/usr/bin/bash

# Termux 增强版卸载脚本

echo "正在卸载 Termux 增强版脚本..."

# 移除启动脚本
if [ -f "$install_file" ]; then
    rm -f "$install_file"
    echo "✓ 移除启动脚本"
fi

# 从.bashrc中移除
if [ -f "$bashrc_file" ]; then
    sed -i '/termuxtool/d' "$bashrc_file"
    echo "✓ 从.bashrc中移除"
fi

# 移除别名
unalias tool 2>/dev/null

echo -e "\n✅ Termux 增强版脚本已卸载"
echo "请重新启动Termux或执行: source ~/.bashrc"
EOF
    chmod +x "$uninstall_file"
    
    print_status success "脚本安装完成"
    print_table_row "启动脚本" "$install_file"
    print_table_row "卸载脚本" "$uninstall_file"
    print_table_row "快捷命令" "tool"
    
    echo -e "\n${COLOR_YELLOW}💡 安装完成！${COLOR_RESET}"
    print_list_item "下次启动Termux时自动运行增强脚本"
    print_list_item "输入 'tool' 快速启动脚本"
    print_list_item "运行 '$uninstall_file' 卸载脚本"
}

uninstall_script() {
    print_section "🗑️ 脚本卸载"
    
    local install_file="$HOME/.termux/boot/termuxtool.sh"
    local uninstall_file="$HOME/.termux/boot/uninstall_tool.sh"
    local bashrc_file="$HOME/.bashrc"
    
    if [ ! -f "$install_file" ]; then
        print_status warning "脚本未安装"
        return 1
    fi
    
    echo -e "${COLOR_YELLOW}确认卸载 Termux 增强版脚本?${COLOR_RESET}"
    read -p "选择 (y/N): " confirm_uninstall
    
    if [[ ! "$confirm_uninstall" =~ ^[Yy]$ ]]; then
        print_status info "取消卸载"
        return
    fi
    
    # 移除启动脚本
    start_progress "移除启动脚本"
    rm -f "$install_file"
    end_progress
    
    # 移除卸载脚本
    if [ -f "$uninstall_file" ]; then
        rm -f "$uninstall_file"
    fi
    
    # 从.bashrc中移除
    start_progress "清理.bashrc"
    sed -i '/termuxtool/d' "$bashrc_file"
    end_progress
    
    # 移除别名
    unalias tool 2>/dev/null
    
    print_status success "脚本卸载完成"
    echo -e "\n${COLOR_YELLOW}💡 请重新启动Termux或执行: source ~/.bashrc${COLOR_RESET}"
}

# -------------------------- 自动测试并选择镜像 --------------------------
auto_select_mirror() {
    print_section "⚡ 自动测试并选择镜像"
    
    local mirrors=(
        "https://gitclone.com/github.com/octocat/Hello-World.git"
        "https://mirror.ghproxy.com/https://github.com/octocat/Hello-World.git"
        "https://ghproxy.com/https://github.com/octocat/Hello-World.git"
        "https://github.com/octocat/Hello-World.git"
    )
    
    local mirror_names=("gitclone.com" "ghproxy.com" "ghproxy.com(备用)" "官方源")
    local mirror_speeds=()
    local mirror_status=()
    
    echo -e "${COLOR_CYAN}正在测试镜像速度...${COLOR_RESET}"
    
    # 创建临时文件存储结果
    local tmp_dir=$(mktemp -d)
    
    for i in "${!mirrors[@]}"; do
        printf "\r测试进度: %d/%d" $((i+1)) ${#mirrors[@]}
        
        local start_time=$(date +%s%N)
        if timeout 5 git ls-remote --heads "${mirrors[$i]}" > /dev/null 2>&1; then
            local end_time=$(date +%s%N)
            local duration=$(( (end_time - start_time) / 1000000 ))
            mirror_speeds[$i]=$duration
            mirror_status[$i]="✅ 可用 (${duration}ms)"
        else
            mirror_speeds[$i]=999999
            mirror_status[$i]="❌ 不可用"
        fi
    done
    printf "\n"
    
    # 显示测试结果
    echo -e "\n${COLOR_CYAN}镜像测试结果:${COLOR_RESET}"
    for i in "${!mirrors[@]}"; do
        echo -e "  ${mirror_status[$i]} - ${mirror_names[$i]}"
    done
    
    # 找出最快的可用镜像
    local fastest_index=-1
    local fastest_speed=999999
    
    for i in "${!mirror_speeds[@]}"; do
        if [ "${mirror_speeds[$i]}" -lt "$fastest_speed" ] && [[ "${mirror_status[$i]}" == *"✅"* ]]; then
            fastest_speed=${mirror_speeds[$i]}
            fastest_index=$i
        fi
    done
    
    if [ $fastest_index -eq -1 ]; then
        print_status error "没有可用的镜像"
        return 1
    fi
    
    local fastest_mirror="${mirrors[$fastest_index]}"
    local fastest_name="${mirror_names[$fastest_index]}"
    
    echo -e "\n${COLOR_CYAN}最快镜像: ${COLOR_GREEN}${fastest_name} (${fastest_speed}ms)${COLOR_RESET}"
    
    # 自动配置镜像
    git config --global --unset url."https://gitclone.com/github.com/".insteadOf 2>/dev/null
    git config --global --unset url."https://mirror.ghproxy.com/https://github.com/".insteadOf 2>/dev/null
    git config --global --unset url."https://ghproxy.com/https://github.com/".insteadOf 2>/dev/null
    
    if [ "$fastest_mirror" != "https://github.com/octocat/Hello-World.git" ]; then
        local mirror_url="${fastest_mirror%.git}"
        mirror_url="${mirror_url%/octocat/Hello-World}"
        git config --global url."$mirror_url".insteadOf https://github.com/
        print_status success "已自动配置最快镜像: ${mirror_url}"
    else
        print_status success "官方源速度最快，使用官方源"
    fi
    
    # 显示当前配置
    local current_mirror=$(git config --global --get-regexp url | grep github | awk '{print $2}' || echo "官方源")
    echo -e "${COLOR_CYAN}当前Git镜像配置: ${COLOR_GREEN}$current_mirror${COLOR_RESET}"
    
    # 清理临时文件
    rm -rf "$tmp_dir"
}

# -------------------------- Termux 常用命令大全 --------------------------
show_termux_commands() {
    print_section "📚 Termux 常用命令大全"
    
    echo -e "${COLOR_CYAN}📦 包管理命令:${COLOR_RESET}"
    print_list_item "pkg update - 更新软件包列表"
    print_list_item "pkg upgrade - 升级所有软件包"
    print_list_item "pkg install <包名> - 安装软件包"
    print_list_item "pkg remove <包名> - 卸载软件包"
    print_list_item "pkg search <关键词> - 搜索软件包"
    print_list_item "pkg list-all - 列出所有可用包"
    print_list_item "pkg show <包名> - 显示包信息"
    print_list_item "pkg files <包名> - 显示包的文件"
    
    echo -e "\n${COLOR_CYAN}📁 文件管理命令:${COLOR_RESET}"
    print_list_item "ls, ll, la - 列出文件"
    print_list_item "cd <目录> - 切换目录"
    print_list_item "pwd - 显示当前目录"
    print_list_item "mkdir <目录> - 创建目录"
    print_list_item "rm <文件> - 删除文件"
    print_list_item "rm -rf <目录> - 删除目录"
    print_list_item "cp <源> <目标> - 复制文件"
    print_list_item "mv <源> <目标> - 移动/重命名"
    print_list_item "cat <文件> - 显示文件内容"
    print_list_item "nano/vim <文件> - 编辑文件"
    print_list_item "find <目录> -name <模式> - 查找文件"
    
    echo -e "\n${COLOR_CYAN}🌐 网络操作命令:${COLOR_RESET}"
    print_list_item "ping <地址> - 网络连通测试"
    print_list_item "curl <URL> - 网络请求"
    print_list_item "wget <URL> - 下载文件"
    print_list_item "ssh <用户@主机> - SSH连接"
    print_list_item "scp <文件> <用户@主机:路径> - 安全复制"
    print_list_item "ifconfig/ip a - 查看网络接口"
    print_list_item "netstat -tulpn - 查看网络连接"
    print_list_item "dig/nslookup <域名> - DNS查询"
    
    echo -e "\n${COLOR_CYAN}🔧 系统管理命令:${COLOR_RESET}"
    print_list_item "top/htop - 进程监控"
    print_list_item "ps aux - 查看进程"
    print_list_item "kill <PID> - 终止进程"
    print_list_item "df -h - 磁盘使用情况"
    print_list_item "du -sh <目录> - 目录大小"
    print_list_item "free -h - 内存使用情况"
    print_list_item "uname -a - 系统信息"
    print_list_item "whoami - 当前用户"
    print_list_item "date - 日期时间"
    print_list_item "cal - 日历"
    
    echo -e "\n${COLOR_CYAN}📊 Git 相关命令:${COLOR_RESET}"
    print_list_item "git clone <仓库> - 克隆仓库"
    print_list_item "git pull - 拉取更新"
    print_list_item "git push - 推送更改"
    print_list_item "git add <文件> - 添加文件"
    print_list_item "git commit -m '消息' - 提交更改"
    print_list_item "git status - 查看状态"
    print_list_item "git log --oneline - 查看日志"
    print_list_item "git branch - 查看分支"
    print_list_item "git checkout <分支> - 切换分支"
    
    echo -e "\n${COLOR_CYAN}🛠️ Termux 特有命令:${COLOR_RESET}"
    print_list_item "termux-setup-storage - 设置存储权限"
    print_list_item "termux-change-repo - 更换软件源"
    print_list_item "termux-info - 系统信息"
    print_list_item "termux-battery-status - 电池状态"
    print_list_item "termux-brightness <值> - 屏幕亮度"
    print_list_item "termux-volume <类型> <值> - 音量控制"
    print_list_item "termux-vibrate - 振动"
    print_list_item "termux-toast <消息> - 显示Toast"
    print_list_item "termux-notification <标题> <内容> - 通知"
    
    echo -e "\n${COLOR_CYAN}🔐 权限管理命令:${COLOR_RESET}"
    print_list_item "chmod <权限> <文件> - 修改权限"
    print_list_item "chown <用户:组> <文件> - 修改所有者"
    print_list_item "su - 切换root"
    print_list_item "sudo <命令> - 以root执行"
    
    echo -e "\n${COLOR_CYAN}📝 文本处理命令:${COLOR_RESET}"
    print_list_item "grep <模式> <文件> - 文本搜索"
    print_list_item "sed 's/旧/新/g' <文件> - 文本替换"
    print_list_item "awk '{print $1}' <文件> - 文本分析"
    print_list_item "sort <文件> - 排序"
    print_list_item "uniq <文件> - 去重"
    print_list_item "wc -l <文件> - 行数统计"
    
    echo -e "\n${COLOR_CYAN}📦 压缩解压命令:${COLOR_RESET}"
    print_list_item "tar -czf 输出.tar.gz 输入 - 压缩为tar.gz"
    print_list_item "tar -xzf 输入.tar.gz - 解压tar.gz"
    print_list_item "zip 输出.zip 输入 - 压缩为zip"
    print_list_item "unzip 输入.zip - 解压zip"
    print_list_item "7z x 输入.7z - 解压7z"
    
    echo -e "\n${COLOR_YELLOW}💡 提示: 使用 'man <命令>' 查看详细帮助${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}💡 提示: 使用 'alias' 查看所有别名${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}💡 提示: 使用 'history' 查看命令历史${COLOR_RESET}"
}

# -------------------------- 镜像源配置功能 --------------------------
configure_termux_mirror() {
    print_section "🔄 Termux 镜像源配置"
    
    echo -e "${COLOR_CYAN}选择镜像源:${COLOR_RESET}"
    print_list_item "1) 清华大学镜像站 (推荐)"
    print_list_item "2) 北京外国语大学镜像站"
    print_list_item "3) 南京大学镜像站"
    print_list_item "4) 上海交通大学镜像站"
    print_list_item "5) 阿里云镜像站"
    print_list_item "6) 官方源"
    print_list_item "0) 取消"
    
    read -p "请输入选项 [0-6]: " mirror_choice
    
    case $mirror_choice in
        1)
            termux-change-repo \
                --remove http://dl.bintray.com/grimler/game-packages-24 \
                --remove http://dl.bintray.com/grimler/science-packages-24 \
                --add https://mirrors.tuna.tsinghua.edu.cn/termux/termux-packages-24 \
                --add https://mirrors.tuna.tsinghua.edu.cn/termux/game-packages-24 \
                --add https://mirrors.tuna.tsinghua.edu.cn/termux/science-packages-24
            print_status success "已切换到清华大学镜像站"
            ;;
        2)
            termux-change-repo \
                --remove http://dl.bintray.com/grimler/game-packages-24 \
                --remove http://dl.bintray.com/grimler/science-packages-24 \
                --add https://mirrors.bfsu.edu.cn/termux/termux-packages-24 \
                --add https://mirrors.bfsu.edu.cn/termux/game-packages-24 \
                --add https://mirrors.bfsu.edu.cn/termux/science-packages-24
            print_status success "已切换到北京外国语大学镜像站"
            ;;
        3)
            termux-change-repo \
                --remove http://dl.bintray.com/grimler/game-packages-24 \
                --remove http://dl.bintray.com/grimler/science-packages-24 \
                --add https://mirrors.nju.edu.cn/termux/termux-packages-24 \
                --add https://mirrors.nju.edu.cn/termux/game-packages-24 \
                --add https://mirrors.nju.edu.cn/termux/science-packages-24
            print_status success "已切换到南京大学镜像站"
            ;;
        4)
            termux-change-repo \
                --remove http://dl.bintray.com/grimler/game-packages-24 \
                --remove http://dl.bintray.com/grimler/science-packages-24 \
                --add https://mirror.sjtu.edu.cn/termux/termux-packages-24 \
                --add https://mirror.sjtu.edu.cn/termux/game-packages-24 \
                --add https://mirror.sjtu.edu.cn/termux/science-packages-24
            print_status success "已切换到上海交通大学镜像站"
            ;;
        5)
            termux-change-repo \
                --remove http://dl.bintray.com/grimler/game-packages-24 \
                --remove http://dl.bintray.com/grimler/science-packages-24 \
                --add https://mirrors.aliyun.com/termux/termux-packages-24 \
                --add https://mirrors.aliyun.com/termux/game-packages-24 \
                --add https://mirrors.aliyun.com/termux/science-packages-24
            print_status success "已切换到阿里云镜像站"
            ;;
        6)
            termux-change-repo \
                --remove https://mirrors.tuna.tsinghua.edu.cn/termux/termux-packages-24 \
                --remove https://mirrors.tuna.tsinghua.edu.cn/termux/game-packages-24 \
                --remove https://mirrors.tuna.tsinghua.edu.cn/termux/science-packages-24 \
                --add https://packages.termux.org/apt/termux-main/termux-packages-24 \
                --add https://packages.termux.org/apt/termux-games/game-packages-24 \
                --add https://packages.termux.org/apt/termux-science/science-packages-24
            print_status success "已切换到官方源"
            ;;
        0)
            print_status info "取消镜像源切换"
            ;;
        *)
            print_status error "无效的选项"
            ;;
    esac
}

# -------------------------- 一键开关和检查全局镜像功能 --------------------------
toggle_global_mirror() {
    if git config --global --get-regexp url | grep -q github; then
        git config --global --unset url."https://gitclone.com/github.com/".insteadOf 2>/dev/null
        git config --global --unset url."https://mirror.ghproxy.com/https://github.com/".insteadOf 2>/dev/null
        git config --global --unset url."https://ghproxy.com/https://github.com/".insteadOf 2>/dev/null
        print_status success "已关闭所有Git镜像，使用官方源"
    else
        echo -e "${COLOR_CYAN}选择要开启的Git镜像:${COLOR_RESET}"
        print_list_item "1) gitclone.com (国内推荐)"
        print_list_item "2) ghproxy.com (国内推荐)"
        print_list_item "3) ghproxy.com (备用)"
        read -p "请输入选项 [1-3]: " mirror_choice
        
        case $mirror_choice in
            1)
                git config --global url."https://gitclone.com/github.com/".insteadOf https://github.com/
                print_status success "已开启 gitclone.com 镜像"
                ;;
            2)
                git config --global url."https://mirror.ghproxy.com/https://github.com/".insteadOf https://github.com/
                print_status success "已开启 ghproxy.com 镜像"
                ;;
            3)
                git config --global url."https://ghproxy.com/https://github.com/".insteadOf https://github.com/
                print_status success "已开启 ghproxy.com 镜像"
                ;;
            *)
                print_status error "无效选项"
                ;;
        esac
    fi
}

check_global_mirror() {
    local mirrors=$(git config --global --get-regexp url | grep github | awk '{print $2}' || echo "未设置镜像")
    if [ "$mirrors" != "未设置镜像" ]; then
        print_status success "当前Git镜像配置:"
        git config --global --get-regexp url | grep github | while read line; do
            echo "  ${COLOR_GREEN}✓${COLOR_RESET} $line"
        done
    else
        print_status info "当前未配置Git镜像，使用官方源"
    fi
}

# -------------------------- 自动更新功能 --------------------------
check_for_updates() {
    print_subsection "检查更新"
    
    start_progress "检查脚本更新"
    
    local latest_version=""
    local sources=(
        "$SCRIPT_UPDATE_URL"
        "https://gitee.com/mirror_termux/termuxtool/raw/main/version.txt"
    )
    
    for source in "${sources[@]}"; do
        latest_version=$(curl -s --max-time 5 "$source" 2>/dev/null | head -n 1 | tr -cd '[:alnum:].-')
        if [ -n "$latest_version" ] && [ "$latest_version" != "$SCRIPT_VERSION" ]; then
            end_progress
            print_status info "发现新版本: $latest_version (当前: $SCRIPT_VERSION)"
            
            echo -e "${COLOR_YELLOW}是否更新到最新版本?${COLOR_RESET}"
            read -p "选择 (y/N): " update_choice
            
            if [[ "$update_choice" =~ ^[Yy]$ ]]; then
                update_script "$latest_version"
            else
                print_status info "跳过更新"
            fi
            return
        elif [ -n "$latest_version" ]; then
            end_progress
            print_status success "已是最新版本 ($SCRIPT_VERSION)"
            return
        fi
    done
    
    end_progress
    print_status info "无法检查更新，继续使用当前版本 ($SCRIPT_VERSION)"
}

update_script() {
    local version=$1
    print_subsection "更新脚本到版本 $version"
    
    local backup_file="$HOME/termuxtool_backup_$(date +%Y%m%d_%H%M%S).sh"
    cp "$0" "$backup_file"
    print_status info "当前脚本已备份到: $backup_file"
    
    local sources=(
        "$SCRIPT_SOURCE_URL"
        "https://gitee.com/mirror_termux/termuxtool/raw/main/termuxtool.sh"
    )
    
    for source in "${sources[@]}"; do
        start_progress "从 $(echo $source | cut -d'/' -f3) 下载"
        
        if curl -fsSL --max-time 10 "$source" -o "$HOME/termuxtool_new.sh" 2>/dev/null; then
            end_progress
            
            if [ -s "$HOME/termuxtool_new.sh" ] && head -n 5 "$HOME/termuxtool_new.sh" | grep -q "Termux 增强版"; then
                chmod +x "$HOME/termuxtool_new.sh"
                mv "$HOME/termuxtool_new.sh" "$0"
                print_status success "脚本更新成功！"
                print_status info "请重新运行脚本以应用更新"
                exit 0
            else
                print_status error "下载的文件无效"
                rm -f "$HOME/termuxtool_new.sh"
            fi
        else
            end_progress
        fi
    done
    
    print_status error "更新失败，请稍后重试"
}

# -------------------------- GitHub PAT配置函数 --------------------------
check_github_connectivity() {
    start_progress "检测GitHub连通性"
    if curl -fsSL --max-time 5 "$CHECK_URL_GITHUB" > /dev/null 2>&1; then
        end_progress
        return 0
    else
        end_progress
        return 1
    fi
}

setup_github_pat() {
    if [ -f "$GITHUB_PAT_FILE" ]; then
        local current_user=$(cat "$GITHUB_USER_FILE" 2>/dev/null || echo "未知用户")
        print_status info "GitHub PAT已配置 (用户: ${current_user})"
        
        echo -e "\n${COLOR_YELLOW}是否重新配置GitHub PAT?${COLOR_RESET}"
        read -p "选择 (y/N): " reconfirm
        if [[ ! "$reconfirm" =~ ^[Yy]$ ]]; then
            return
        fi
    fi

    print_section "GitHub PAT配置"
    
    echo -e "${COLOR_CYAN}GitHub Personal Access Token (PAT) 用于：${COLOR_RESET}"
    print_list_item "提高Git操作速率限制 (5000次/小时)"
    print_list_item "访问私有仓库"
    print_list_item "执行GitHub API操作"
    echo -e "\n${COLOR_YELLOW}创建PAT步骤：${COLOR_RESET}"
    print_list_item "访问 https://github.com/settings/tokens"
    print_list_item "点击 'Generate new token (classic)'"
    print_list_item "选择权限: repo, gist, read:org, workflow"
    print_list_item "复制生成的Token"
    echo ""
    
    read -p "请输入GitHub用户名: " github_user
    read -s -p "请输入GitHub PAT (输入时不显示): " github_pat
    echo ""
    
    if [ -z "$github_user" ] || [ -z "$github_pat" ]; then
        print_status error "用户名和PAT不能为空"
        return 1
    fi
    
    # 测试PAT有效性
    start_progress "验证PAT有效性"
    local test_response=$(curl -s -H "Authorization: token $github_pat" \
        "https://api.github.com/user" 2>/dev/null)
    end_progress
    
    local login_name=$(echo "$test_response" | grep -o '"login": "[^"]*"' | cut -d'"' -f4)
    
    if [ "$login_name" = "$github_user" ]; then
        # 保存PAT
        echo "$github_pat" > "$GITHUB_PAT_FILE"
        chmod 600 "$GITHUB_PAT_FILE"
        echo "$github_user" > "$GITHUB_USER_FILE"
        
        # 配置Git凭据
        echo "https://${github_user}:${github_pat}@github.com" > "$GITHUB_CREDENTIALS_FILE"
        chmod 600 "$GITHUB_CREDENTIALS_FILE"
        git config --global credential.helper store
        
        print_status success "GitHub PAT配置成功！"
        print_table_row "用户名" "$github_user"
        print_table_row "PAT文件" "$GITHUB_PAT_FILE"
        print_table_row "凭据文件" "$GITHUB_CREDENTIALS_FILE"
        
        # 验证Git配置
        start_progress "测试Git配置"
        if git ls-remote "https://github.com/$github_user" > /dev/null 2>&1; then
            end_progress
            print_status success "Git配置验证成功"
        else
            end_progress
            print_status warning "Git配置验证失败，请检查网络或PAT权限"
        fi
    else
        print_status error "PAT验证失败"
        echo -e "${COLOR_YELLOW}返回信息:${COLOR_RESET}"
        echo "$test_response" | head -5
    fi
}

remove_github_pat() {
    if [ -f "$GITHUB_PAT_FILE" ]; then
        rm -f "$GITHUB_PAT_FILE"
        rm -f "$GITHUB_CREDENTIALS_FILE"
        rm -f "$GITHUB_USER_FILE"
        git config --global --unset credential.helper
        print_status success "GitHub PAT配置已移除"
    else
        print_status info "未找到GitHub PAT配置"
    fi
}

show_github_status() {
    if [ -f "$GITHUB_PAT_FILE" ]; then
        local user=$(cat "$GITHUB_USER_FILE" 2>/dev/null || echo "未知")
        local pat=$(head -c 10 "$GITHUB_PAT_FILE" 2>/dev/null && echo "...")
        print_status info "GitHub PAT已配置"
        print_table_row "用户" "$user"
        print_table_row "PAT" "$pat"
    else
        print_status info "GitHub PAT未配置"
    fi
}

# -------------------------- 工具函数区 --------------------------
is_valid_ip() {
    local ip=$1
    [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] && return
