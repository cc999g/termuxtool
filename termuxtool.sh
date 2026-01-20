#!/data/data/com.termux/files/usr/bin/bash

# ==============================================
#   ██╗   ██╗ ██████╗
#   ╚██╗ ██╔╝██╔════╝
#    ╚████╔╝ ██║     
#     ╚██╔╝  ██║     
#      ██║   ╚██████╗
#      ╚═╝    ╚═════╝
#
#  Termux 增强版环境配置脚本 v1.4
#  功能：IP检测、代理自动切换、Git镜像管理、延迟测试、交互式配置、GitHub PAT配置
# ==============================================

# -------------------------- 初始化配置 --------------------------
export TERMUX_SCROLLBACK=10000
export HOSTNAME=xiaomi6

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
PROXY_PROTOCOL="http"
PROXY_HOST="127.0.0.1"
PROXY_PORT="7890"
PROXY_USER=""
PROXY_PASS=""

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
DELAY_THRESHOLD=500

# IP检测接口列表
IP_CHECK_API=(
    "https://api.ipify.org"
    "https://icanhazip.com"
    "https://myip.ipip.net"
)

# IP归属地查询接口
LOC_CHECK_API=(
    "http://ip-api.com/json/%IP%?fields=country,city"
    "https://ipinfo.io/%IP%/json"
)

# Git镜像源列表
GIT_MIRROR=(
    "https://gitclone.com/github.com/"
    "https://mirror.ghproxy.com/https://github.com/"
    "https://github.com/"
)
CURRENT_MIRROR=0

# GitHub配置
GITHUB_PAT_FILE="$HOME/.github_pat"
GITHUB_CREDENTIALS_FILE="$HOME/.git-credentials"
GITHUB_USER_FILE="$HOME/.github_user"

# 个性化配置
ENABLE_BOOT_CHECK=true
CONFIG_TIMEOUT=10
ENABLE_PROGRESS_INDICATOR=true

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

progress_bar() {
    local duration=$1
    local steps=30
    local step_duration=$(echo "scale=2; $duration / $steps" | bc -l 2>/dev/null || echo "0.1")
    
    echo -n "["
    for ((i=0; i<steps; i++)); do
        echo -n "█"
        sleep $step_duration
    done
    echo "]"
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
    [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] && return 0 || return 1
}

get_time_ms() {
    echo "$(date +%s)000"
}

get_local_ip() {
    start_progress "获取局域网IP"
    local ip_info=$( (ip -4 addr show || ifconfig) 2>/dev/null | awk '/inet / && !/127.0.0.1/ {
        split($2, ip_arr, "/"); nic=$NF; gsub(/@.*|:.*|inet/, "", nic);
        if (ip_arr[1] != "") printf "%s (%s) | ", ip_arr[1], nic
    }' | sed 's/ | $//; s/^ | //' || echo "未获取到")
    end_progress
    echo "$ip_info"
}

get_public_ip() {
    start_progress "获取公网IP"
    local ip="获取失败"
    
    for api in "${IP_CHECK_API[@]}"; do
        local tmp_ip=$(curl -s --max-time 5 $api 2>/dev/null | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")
        if is_valid_ip "$tmp_ip"; then
            ip=$tmp_ip
            break
        fi
    done
    end_progress
    echo "$ip"
}

get_ip_location() {
    local ip=$1
    if ! is_valid_ip "$ip" || [[ $ip =~ ^192\.168\. ]] || [[ $ip =~ ^10\. ]] || [[ $ip =~ ^172\.1[6-9]\. ]] || [[ $ip =~ ^172\.2[0-9]\. ]] || [[ $ip =~ ^172\.3[0-1]\. ]]; then
        echo ""
        return
    fi

    for api in "${LOC_CHECK_API[@]}"; do
        local loc=$(curl -s --max-time 3 "${api//%IP%/$ip}" 2>/dev/null | sed 's/[}{"]//g')
        local country=$(echo $loc | awk -F 'country:|,city:' '{print $2}')
        local city=$(echo $loc | awk -F 'city:|,region:' '{print $2}')
        
        if [ -n "$country" ] && [ "$country" != "null" ] && [ -n "$city" ] && [ "$city" != "null" ]; then
            echo "$country / $city"
            return
        fi
    done
    echo "未知"
}

test_delay() {
    local use_proxy=$1
    local total_delay=0
    local success_count=0

    if [ "$use_proxy" = "true" ] && [ -n "$http_proxy" ]; then
        for ((i=1; i<=DELAY_TEST_COUNT; i++)); do
            local delay=$(curl -x "$http_proxy" -s -w "%{time_total}\n" -o /dev/null --max-time 5 --connect-timeout 3 "$TEST_URL" 2>/dev/null)
            if [ -n "$delay" ] && (( $(echo "$delay > 0" | bc -l 2>/dev/null || echo "0") )); then
                total_delay=$(echo "$total_delay + $delay" | bc -l 2>/dev/null || echo "0")
                success_count=$((success_count + 1))
            fi
        done
    else
        if ! command -v ping &> /dev/null; then
            echo "检测失败"
            return
        fi
        ping_result=$(ping -c $DELAY_TEST_COUNT -W 3 "$TEST_URL" 2>/dev/null | grep "avg" | awk -F '/' '{print $5}')
        if [ -n "$ping_result" ]; then
            echo "${ping_result}ms"
            return
        fi
    done

    [ $success_count -eq 0 ] && echo "检测失败" && return
    local avg_delay=$(echo "scale=1; ($total_delay / $success_count) * 1000" | bc -l 2>/dev/null || echo "0")
    echo "${avg_delay}ms"
}

delay_alert() {
    local delay=$1
    if [ "$delay" = "检测失败" ]; then
        print_status warning "延迟检测失败"
        return
    fi
    [[ $delay =~ ^[0-9.]+ms$ ]] || { echo $delay; return; }
    local delay_num=${delay%ms}
    
    if (( $(echo "$delay_num > $DELAY_THRESHOLD" | bc -l 2>/dev/null || echo "0") )); then
        echo -e "${STYLE_ERROR}$delay (超过阈值 ${DELAY_THRESHOLD}ms)${COLOR_RESET}"
    else
        echo -e "${STYLE_SUCCESS}$delay${COLOR_RESET}"
    fi
}

# -------------------------- Git镜像管理 --------------------------
git_mirror_switch() {
    CURRENT_MIRROR=$(( (CURRENT_MIRROR + 1) % ${#GIT_MIRROR[@]} ))
    local mirror=${GIT_MIRROR[$CURRENT_MIRROR]}
    
    git config --global --unset url."https://gitclone.com/github.com/".insteadOf 2>/dev/null
    git config --global --unset url."https://mirror.ghproxy.com/https://github.com/".insteadOf 2>/dev/null
    
    if [ "$mirror" != "https://github.com/" ]; then
        git config --global url."$mirror".insteadOf https://github.com/
        print_status success "Git镜像已切换至: $mirror"
    else
        print_status info "Git已切换至官方源"
    fi
}

git_mirror_check() {
    local current=$(git config --global --get-regexp url | grep github | awk '{print $1}' | sed 's/url\.//; s/\.insteadOf//')
    if [ -n "$current" ]; then
        print_status success "当前Git镜像: $current"
    else
        print_status info "当前Git使用官方源"
    fi
}

test_git_mirror_speed() {
    echo -e "${COLOR_CYAN}测试Git镜像速度...${COLOR_RESET}"
    
    local mirrors=(
        "https://gitclone.com/github.com/octocat/Hello-World.git"
        "https://mirror.ghproxy.com/https://github.com/octocat/Hello-World.git"
        "https://github.com/octocat/Hello-World.git"
    )
    
    local mirror_names=("gitclone.com" "ghproxy.com" "官方源")
    
    for i in "${!mirrors[@]}"; do
        start_progress "测试 ${mirror_names[$i]}"
        local start_time=$(date +%s%N)
        git ls-remote --heads "${mirrors[$i]}" > /dev/null 2>&1
        local end_time=$(date +%s%N)
        local duration=$(( (end_time - start_time) / 1000000 ))
        end_progress
        
        if [ $? -eq 0 ]; then
            echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} ${mirror_names[$i]}: ${duration}ms"
        else
            echo -e "  ${COLOR_RED}✗${COLOR_RESET} ${mirror_names[$i]}: 失败"
        fi
    done
}

# -------------------------- 代理管理函数 --------------------------
check_direct_connect() {
    local baidu_ok=1
    local google_ok=1
    local github_ok=1

    print_subsection "直连连通性检测"
    
    start_progress "检测百度"
    if curl -fsSL --max-time 3 "$CHECK_URL_BAIDU" > /dev/null 2>&1; then
        baidu_ok=0
        end_progress
        print_status success "国内地址(百度)可访问"
    else
        end_progress
        print_status error "国内地址(百度)不可访问"
    fi

    start_progress "检测Google"
    if curl -fsSL --max-time 3 "$CHECK_URL_GOOGLE" > /dev/null 2>&1; then
        google_ok=0
        end_progress
        print_status success "国外地址(Google)可访问"
    else
        end_progress
        print_status error "国外地址(Google)不可访问"
    fi

    start_progress "检测GitHub"
    if curl -fsSL --max-time 3 "$CHECK_URL_GITHUB" > /dev/null 2>&1; then
        github_ok=0
        end_progress
        print_status success "代码仓库(GitHub)可访问"
    else
        end_progress
        print_status error "代码仓库(GitHub)不可访问"
    fi

    return $google_ok
}

check_proxy_available() {
    print_subsection "代理可用性检测"
    start_progress "测试代理"
    
    if [ "$PROXY_PROTOCOL" = "http" ]; then
        if curl -fsSL --max-time 3 --proxy "$PROXY_HTTP" "$CHECK_URL_GOOGLE" > /dev/null 2>&1; then
            end_progress
            print_status success "代理可用 (HTTP)"
            return 0
        else
            end_progress
            print_status error "代理不可用 (HTTP)"
            return 1
        fi
    else
        if curl -fsSL --max-time 3 --proxy "$PROXY_SOCKS5" "$CHECK_URL_GOOGLE" > /dev/null 2>&1; then
            end_progress
            print_status success "代理可用 (SOCKS5)"
            return 0
        else
            end_progress
            print_status error "代理不可用 (SOCKS5)"
            return 1
        fi
    fi
}

set_proxy() {
    if [ "$PROXY_STATUS" = "P 🟢" ]; then
        print_status info "代理已处于开启状态"
        return
    fi
    
    if [ "$PROXY_PROTOCOL" = "http" ]; then
        export http_proxy="$PROXY_HTTP"
        export https_proxy="$PROXY_HTTP"
        export ALL_PROXY=""
        git config --global http.proxy "$PROXY_HTTP" 2>/dev/null
        git config --global https.proxy "$PROXY_HTTP" 2>/dev/null
        print_status success "HTTP代理已开启: ${PROXY_HTTP//:$PROXY_PASS/:***}"
    else
        export http_proxy=""
        export https_proxy=""
        export ALL_PROXY="$PROXY_SOCKS5"
        git config --global http.proxy "$PROXY_SOCKS5" 2>/dev/null
        git config --global https.proxy "$PROXY_SOCKS5" 2>/dev/null
        print_status success "SOCKS5代理已开启: ${PROXY_SOCKS5//:$PROXY_PASS/:***}"
    fi
    
    export PROXY_STATUS="P 🟢"
    
    print_subsection "代理生效验证"
    start_progress "验证代理"
    local proxy_ip=$(get_public_ip)
    local proxy_loc=$(get_ip_location "$proxy_ip")
    end_progress
    
    if [ "$proxy_ip" != "获取失败" ] && [ "$proxy_ip" != "未知IP" ]; then
        print_status success "代理生效"
        print_table_row "代理IP" "$proxy_ip"
        print_table_row "归属地" "${proxy_loc:-未知}"
        
        start_progress "测试延迟"
        local proxy_delay=$(test_delay true)
        end_progress
        echo -e "  延迟: $(delay_alert $proxy_delay)"
    else
        print_status warning "代理可能未正确生效"
    fi
}

unset_proxy() {
    if [ "$PROXY_STATUS" = "P ❌" ]; then
        print_status info "代理已处于关闭状态"
        return
    fi
    unset http_proxy https_proxy ALL_PROXY
    git config --global --unset http.proxy 2>/dev/null
    git config --global --unset https_proxy 2>/dev/null
    export PROXY_STATUS="P ❌"
    print_status success "系统全局代理已关闭"
}

# -------------------------- 交互式配置函数 --------------------------
interactive_proxy_config() {
    print_section "代理服务器配置"
    
    echo -e "${COLOR_CYAN}当前代理配置:${COLOR_RESET}"
    print_table_row "协议" "$PROXY_PROTOCOL"
    print_table_row "地址" "$PROXY_HOST:$PROXY_PORT"
    if [ -n "$PROXY_USER" ]; then
        print_table_row "用户" "$PROXY_USER"
        print_table_row "密码" "******"
    fi
    
    echo -e "\n${COLOR_YELLOW}是否修改代理配置?${COLOR_RESET} (${CONFIG_TIMEOUT}秒后跳过)"
    if read -t $CONFIG_TIMEOUT -p "选择 [y/N]: " proxy_choice; then
        if [[ "$proxy_choice" =~ ^[Yy]$ ]]; then
            echo -e "\n${COLOR_CYAN}选择代理协议:${COLOR_RESET}"
            print_list_item "1) HTTP/HTTPS代理 (常用)"
            print_list_item "2) SOCKS5代理"
            read -p "请输入选项 [1-2] (默认 1): " protocol_choice
            
            case ${protocol_choice:-1} in
                1) new_protocol="http" ;;
                2) new_protocol="socks5" ;;
                *) new_protocol="http" ;;
            esac
            
            read -p "请输入代理主机 [127.0.0.1]: " new_host
            read -p "请输入代理端口 [7890]: " new_port
            
            new_host=${new_host:-"127.0.0.1"}
            new_port=${new_port:-"7890"}
            
            if ! [[ "$new_port" =~ ^[0-9]+$ ]]; then
                print_status error "端口必须是数字"
                return 1
            fi
            
            echo -e "\n${COLOR_CYAN}代理认证设置:${COLOR_RESET}"
            read -p "是否需要代理认证? (y/N): " auth_choice
            
            new_user=""
            new_pass=""
            
            if [[ "$auth_choice" =~ ^[Yy]$ ]]; then
                read -p "请输入代理用户名: " new_user
                read -s -p "请输入代理密码: " new_pass
                echo ""
                
                if [ -n "$new_pass" ]; then
                    read -s -p "请再次输入代理密码: " new_pass_confirm
                    echo ""
                    
                    if [ "$new_pass" != "$new_pass_confirm" ]; then
                        print_status error "两次输入的密码不一致"
                        return 1
                    fi
                fi
            fi
            
            PROXY_PROTOCOL="$new_protocol"
            PROXY_HOST="$new_host"
            PROXY_PORT="$new_port"
            PROXY_USER="$new_user"
            PROXY_PASS="$new_pass"
            
            sed -i "s/^PROXY_PROTOCOL=.*/PROXY_PROTOCOL=\"$PROXY_PROTOCOL\"/" ~/.bashrc
            sed -i "s/^PROXY_HOST=.*/PROXY_HOST=\"$PROXY_HOST\"/" ~/.bashrc
            sed -i "s/^PROXY_PORT=.*/PROXY_PORT=\"$PROXY_PORT\"/" ~/.bashrc
            sed -i "s/^PROXY_USER=.*/PROXY_USER=\"$PROXY_USER\"/" ~/.bashrc
            sed -i "s/^PROXY_PASS=.*/PROXY_PASS=\"$PROXY_PASS\"/" ~/.bashrc
            
            print_status success "代理配置已更新"
            test_proxy_configuration
        else
            print_status info "跳过代理配置"
        fi
    else
        print_status info "配置超时，跳过代理配置"
    fi
}

interactive_git_config() {
    print_section "Git镜像源配置"
    
    local current_mirror=$(git config --global --get-regexp url | grep github | awk '{print $2}' || echo "官方源")
    print_table_row "当前镜像" "$current_mirror"
    
    echo -e "\n${COLOR_YELLOW}是否切换Git镜像源?${COLOR_RESET} (${CONFIG_TIMEOUT}秒后跳过)"
    if read -t $CONFIG_TIMEOUT -p "选择 [y/N]: " git_choice; then
        if [[ "$git_choice" =~ ^[Yy]$ ]]; then
            echo -e "\n${COLOR_CYAN}选择Git镜像源:${COLOR_RESET}"
            print_list_item "1) gitclone.com (国内推荐)"
            print_list_item "2) ghproxy.com (国内推荐)"
            print_list_item "3) 官方源 github.com (直连)"
            print_list_item "0) 保持当前设置"
            
            read -p "请输入选项 [0-3]: " mirror_choice
            
            case $mirror_choice in
                1)
                    git config --global url."https://gitclone.com/github.com/".insteadOf https://github.com/
                    print_status success "已切换至 gitclone.com 镜像"
                    ;;
                2)
                    git config --global url."https://mirror.ghproxy.com/https://github.com/".insteadOf https://github.com/
                    print_status success "已切换至 ghproxy.com 镜像"
                    ;;
                3)
                    git config --global --unset url."https://gitclone.com/github.com/".insteadOf 2>/dev/null
                    git config --global --unset url."https://mirror.ghproxy.com/https://github.com/".insteadOf 2>/dev/null
                    print_status success "已切换至官方源"
                    ;;
                *)
                    print_status info "保持当前Git镜像设置"
                    ;;
            esac
            test_git_mirror_speed
        else
            print_status info "跳过Git镜像配置"
        fi
    else
        print_status info "配置超时，跳过Git镜像配置"
    fi
}

interactive_github_config() {
    print_section "GitHub PAT配置"
    
    show_github_status
    
    echo -e "\n${COLOR_YELLOW}是否配置GitHub PAT?${COLOR_RESET} (${CONFIG_TIMEOUT}秒后跳过)"
    if read -t $CONFIG_TIMEOUT -p "选择 [y/N]: " pat_choice; then
        if [[ "$pat_choice" =~ ^[Yy]$ ]]; then
            setup_github_pat
        else
            print_status info "跳过GitHub PAT配置"
        fi
    else
        print_status info "配置超时，跳过GitHub PAT配置"
    fi
}

interactive_config_menu() {
    print_section "交互式配置菜单"
    
    interactive_proxy_config
    interactive_git_config
    
    if check_github_connectivity; then
        interactive_github_config
    else
        print_status warning "GitHub不可访问，跳过PAT配置"
    fi
    
    print_status success "配置完成"
}

# -------------------------- 依赖检测函数 --------------------------
check_dependencies() {
    local dependencies=("curl" "bc" "awk" "git" "free" "df" "date")
    local missing=()

    for dep in "${dependencies[@]}"; do
        if ! command -v $dep &> /dev/null; then
            missing+=($dep)
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        print_status error "缺失依赖工具: ${missing[*]}"
        echo -e "${COLOR_GREEN}📦 一键安装命令: pkg install ${missing[*]} -y${COLOR_RESET}"
        exit 1
    fi
}

# -------------------------- 主执行流程 --------------------------
clear
check_dependencies
export PROXY_STATUS="P ❌"

# 显示标题
echo -e "${COLOR_PURPLE}"
echo "   ██╗   ██╗ ██████╗"
echo "   ╚██╗ ██╔╝██╔════╝"
echo "    ╚████╔╝ ██║     "
echo "     ╚██╔╝  ██║     "
echo "      ██║   ╚██████╗"
echo "      ╚═╝    ╚═════╝"
echo -e "${COLOR_RESET}"
echo -e "          📌 Termux 增强版环境配置脚本 v1.4"
echo -e "          📌 功能：IP检测、代理切换、Git镜像、GitHub PAT\n"

print_section "欢迎使用 Termux 增强版环境"

if [ "$ENABLE_BOOT_CHECK" = "true" ]; then
    print_section "网络基础信息检测"
    
    LOCAL_IP_FULL=$(get_local_ip)
    PUBLIC_IP_FULL=$(get_public_ip)
    DIRECT_DELAY=$(test_delay false)

    LOCAL_IP=$(echo "$LOCAL_IP_FULL" | awk -F ' | \\| ' '{print $1}')
    PUBLIC_IP=$(echo "$PUBLIC_IP_FULL" | awk '{print $1}')

    if ! is_valid_ip "$PUBLIC_IP"; then
        PUBLIC_IP="未知IP"
        PUBLIC_LOC="无法查询"
    else
        PUBLIC_LOC=$(get_ip_location "$PUBLIC_IP")
    fi

    echo -e "${COLOR_CYAN}🌐 网络信息:${COLOR_RESET}"
    print_table_row "局域网IP" "$LOCAL_IP_FULL"
    print_table_row "公网IP" "$PUBLIC_IP_FULL"
    print_table_row "归属地" "${PUBLIC_LOC:-(局域网IP)}"
    print_table_row "直连延迟" "$(delay_alert $DIRECT_DELAY)"

    check_direct_connect
    google_direct_ok=$?

    PROXY_PUBLIC_IP="未开启"
    PROXY_PUBLIC_LOC="未开启"
    PROXY_DELAY="未检测"
    
    if [ $google_direct_ok -ne 0 ]; then
        print_subsection "代理检测"
        if check_proxy_available; then
            set_proxy
            PROXY_PUBLIC_IP=$(get_public_ip | awk '{print $1}')
            PROXY_PUBLIC_LOC=$(get_ip_location "$PROXY_PUBLIC_IP")
            PROXY_DELAY=$(test_delay true)
            print_table_row "代理IP" "$PROXY_PUBLIC_IP"
            print_table_row "归属地" "${PROXY_PUBLIC_LOC}"
            print_table_row "代理延迟" "$(delay_alert $PROXY_DELAY)"
        else
            unset_proxy
            print_status info "代理不可用，保持直连模式"
        fi
    else
        unset_proxy
        print_status info "国外直连可用，保持直连模式"
    fi

    interactive_config_menu

    print_section "系统信息汇总"
    
    echo -e "${COLOR_CYAN}📋 基础信息:${COLOR_RESET}"
    print_table_row "日期时间" "$(date "+%Y-%m-%d %H:%M:%S")"
    print_table_row "主机名" "$HOSTNAME"
    print_table_row "当前目录" "$(pwd)"
    
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
    
    echo -e "\n${COLOR_CYAN}💻 系统状态:${COLOR_RESET}"
    print_table_row "内存占用" "$(free -h | grep Mem | awk '{print $3 "/" $2}')"
    print_table_row "存储占用" "$(df -h $HOME | grep /data | awk '{print $3 "/" $2 " (" $5 ")"}')"
    print_table_row "电池状态" "$(get_battery_info)"
    
    show_github_status
else
    print_status info "开机检测已关闭"
fi

# -------------------------- 快捷命令别名 --------------------------
alias proxy-on="set_proxy"
alias proxy-off="unset_proxy"
alias proxy-check="check_proxy_available"
alias proxy-set="interactive_proxy_config"
alias proxy-test="check_proxy_available"
alias delay-compare="echo -e '${COLOR_CYAN}📊 延迟对比测试:${COLOR_RESET}' && echo -n '直连延迟: ' && delay_alert \$(test_delay false) && echo -n '代理延迟: ' && delay_alert \$(test_delay true)"

alias git-mirror-switch="git_mirror_switch"
alias git-mirror-check="git_mirror_check"
alias git-mirror-off="git config --global --unset url.*.insteadOf https://github.com/ && echo -e '${STYLE_ERROR}Git所有镜像已关闭${COLOR_RESET}'"
alias git-config="interactive_git_config"
alias git-speed-test="test_git_mirror_speed"
alias github-pat-setup="setup_github_pat"
alias github-pat-remove="remove_github_pat"
alias github-status="show_github_status"

# -------------------------- 命令提示符配置 --------------------------
parse_git_branch() {
    git branch 2>/dev/null | sed -n -e 's/^\* \(.*\)/[\1]/p'
}

get_mirror_status() {
    local current=$(git config --global --get-regexp url | grep github | awk '{print $1}' | sed 's/url\.//; s/\.insteadOf//')
    [ -n "$current" ] && echo -e "${COLOR_PURPLE}M 🟢${COLOR_RESET}" || echo -e "${COLOR_PURPLE}M ❌${COLOR_RESET}"
}

PS1='${COLOR_CYAN}$PROXY_STATUS${COLOR_RESET} $(get_mirror_status) ${COLOR_GREEN}\u@\h:${COLOR_BLUE}\w${COLOR_YELLOW}$(parse_git_branch)${COLOR_RESET}\$ '

# 清理临时函数
unset -f check_dependencies
