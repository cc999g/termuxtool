# Termux 增强版环境配置脚本

![Termux Logo](https://img.shields.io/badge/Termux-增强版-000000?style=for-the-badge&logo=android&logoColor=white)
![Version](https://img.shields.io/badge/版本-1.0-blue.svg)
![License](https://img.shields.io/badge/许可证-MIT-green.svg)

> 一个功能强大的Termux环境增强脚本，集成了IP检测、代理管理、GitHub配置、系统监控等多项实用功能。

## 📋 主要功能

### 🌐 网络功能
- IP地址检测（局域网/公网）
- IP归属地查询
- 网络连通性测试（百度、Google、GitHub）
- 延迟对比测试（直连 vs 代理）
- 代理自动切换与管理

### 🔧 系统工具
- Git配置管理
- GitHub PAT一键配置
- 批量安装常用工具
- 自动清理系统缓存
- 系统信息实时监控

### ⚙️ 配置管理
- 配置导入/导出
- 脚本安装/卸载
- Termux镜像源切换
- 自动更新检查

## 🚀 下载与运行

### 下载脚本

11方法一：直接下载11
11bash
curl -fsSL https://raw.githubusercontent.com/cc999g/termux-enhancer/main/termux_enhancer.sh -o termux_enhancer.sh
11

11方法二：Git克隆11
11bash
git clone https://github.com/cc999g/termux-enhancer.git
cd termux-enhancer
11

### 运行脚本

11方法一：直接运行11
11bash
chmod +x termux_enhancer.sh
./termux_enhancer.sh
11

11方法二：一键运行（不保存文件）11
11bash
curl -fsSL https://raw.githubusercontent.com/cc999g/termux-enhancer/main/termux_enhancer.sh | bash
11

## ⚙️ 永久性配置

### 安装到启动项

运行脚本后，使用以下命令永久安装：

11bash
# 方法1：通过脚本命令
script-install

# 方法2：运行脚本后选择相应选项
11

### 安装后的特性

- 脚本安装在 `~/.termux/boot/termux_enhancer.sh`
- 自动添加到 `.bashrc` 文件
- 每次启动Termux时自动运行
- 可以使用 `enhancer` 命令快速启动（安装后可用）
- 包含卸载脚本 `~/.termux/boot/uninstall_enhancer.sh`

### 卸载脚本

11bash
# 方法1：使用卸载脚本（如果已安装）
bash ~/.termux/boot/uninstall_enhancer.sh

# 方法2：使用快捷命令
script-uninstall
11

## 🔧 基本配置

### 配置文件位置

- **主配置**: `~/.termux_enhancer_config`
- **日志文件**: `~/.termux_enhancer.log`
- **备份目录**: `~/.termux_enhancer_backups`
- **GitHub配置**: `~/.github_pat`, `~/.github_user`, `~/.git-credentials`

### 首次配置步骤

11方法一：交互式配置（推荐）11
运行脚本后，按照提示进行配置：
1. 代理服务器配置
2. GitHub PAT配置  
3. Git基本信息配置

11方法二：手动编辑配置文件11
11bash
# 编辑配置文件
nano ~/.termux_enhancer_config
11

配置文件示例：
11bash
# Termux 增强版配置
PROXY_PROTOCOL="http"
PROXY_HOST="127.0.0.1"
PROXY_PORT="7890"
PROXY_USER=""
PROXY_PASS=""
ENABLE_BOOT_CHECK="true"
ENABLE_PROGRESS_INDICATOR="true"
CONFIG_TIMEOUT="10"
DELAY_THRESHOLD="500"
11

## 🎮 快捷命令使用

脚本提供了以下快捷命令别名：

### 代理相关命令
11bash
proxy-on        # 开启代理
proxy-off       # 关闭代理
proxy-check     # 检测代理状态
proxy-set       # 配置代理服务器
proxy-test      # 测试代理连接
delay-compare   # 延迟对比测试
11

### 网络检测命令
11bash
net-check       # 网络连通性检测
11

### GitHub相关命令
11bash
github-pat-setup    # 配置GitHub PAT
github-pat-remove   # 移除GitHub PAT
github-status       # 查看GitHub状态
11

### 系统工具命令
11bash
system-info         # 显示系统信息
install-tools       # 批量安装工具
termux-commands     # 显示Termux命令大全
termux-mirror       # 切换Termux镜像源
11

### Git配置命令
11bash
git-config-show     # 显示Git配置
git-config-basic    # 配置Git基本信息
11

### 配置管理命令
11bash
export-config       # 导出当前配置
import-config       # 导入配置
script-update       # 检查脚本更新
script-version      # 显示脚本版本
script-install      # 安装脚本到启动项
script-uninstall    # 卸载脚本
11

### 帮助命令
11bash
help               # 显示所有快捷命令
11

## 🔄 更新与维护

### 检查更新
11bash
# 方法1：通过脚本命令
script-update

# 方法2：运行脚本时会自动检查更新
11

### 手动更新
11bash
# 重新下载最新版本
curl -fsSL https://raw.githubusercontent.com/cc999g/termux-enhancer/main/termux_enhancer.sh -o termux_enhancer.sh
chmod +x termux_enhancer.sh
11

### 配置备份与恢复
11bash
# 导出当前配置
export-config

# 导入配置
import-config

# 备份文件存储在：~/.termux_enhancer_backups/
11

## 📁 文件结构说明

11text
~/.termux_enhancer/           # 脚本相关目录
├── termux_enhancer_config    # 主配置文件
├── termux_enhancer.log       # 日志文件
├── .github_pat               # GitHub PAT存储
├── .github_user              # GitHub用户名存储
└── .git-credentials          # Git凭据存储

~/.termux_enhancer_backups/   # 配置备份目录
├── termux_config_20240101_120000.tar.gz
└── termux_config_20240102_150000.tar.gz

~/.termux/boot/               # 启动脚本目录（安装后）
├── termux_enhancer.sh        # 主脚本文件
└── uninstall_enhancer.sh     # 卸载脚本
11

## 🛠️ 故障排除

### 常见问题

1. **脚本运行报错 "command not found"**
   11bash
   pkg install curl git bc -y
   11

2. **无法获取公网IP**
   - 检查网络连接
   - 尝试切换网络（WiFi/移动数据）
   - 可能是防火墙限制

3. **代理无法使用**
   11bash
   # 检查代理配置
   proxy-check
   
   # 重新配置代理
   proxy-set
   11

4. **GitHub PAT配置失败**
   - 确保PAT有正确的权限（repo, gist等）
   - 检查网络是否能访问GitHub
   - 尝试重新生成PAT

5. **查看日志文件**
   11bash
   cat ~/.termux_enhancer.log
   tail -f ~/.termux_enhancer.log  # 实时查看
   11

## 📄 命令行参数

脚本支持以下命令行参数：

11bash
# 显示帮助信息
bash termux_enhancer.sh --help
bash termux_enhancer.sh -h

# 安装脚本到启动项
bash termux_enhancer.sh --install
bash termux_enhancer.sh -i

# 检查更新
bash termux_enhancer.sh --update
bash termux_enhancer.sh -u

# 配置代理
bash termux_enhancer.sh --config
bash termux_enhancer.sh -c

# 显示版本
bash termux_enhancer.sh --version
bash termux_enhancer.sh -v

# 清理缓存（运行脚本时会自动清理）
bash termux_enhancer.sh --clean-cache

# 调试模式
bash termux_enhancer.sh --debug
11

## 📝 注意事项

1. **权限要求**
   - 首次运行建议执行 `termux-setup-storage`
   - 某些功能需要网络权限

2. **兼容性**
   - 仅适用于Termux环境
   - 建议使用最新版Termux

3. **数据安全**
   - PAT和密码等敏感信息存储在本地
   - 配置文件权限自动设置为600
   - 定期备份重要配置

4. **自动清理**
   - 脚本运行时自动清理缓存
   - 不需要单独运行清理命令

## 🤝 贡献与反馈

- **GitHub仓库**: [https://github.com/cc999g/termux-enhancer](https://github.com/cc999g/termux-enhancer)
- **问题反馈**: [GitHub Issues](https://github.com/cc999g/termux-enhancer/issues)
- **作者**: cc999g

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

---

**提示**: 如果觉得这个脚本有用，请在GitHub上给个 ⭐ Star 支持！
