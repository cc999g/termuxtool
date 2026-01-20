# Termux 工具版环境配置脚本

<p align="center">
  <img src="https://img.shields.io/badge/Version-1.0-brightgreen.svg" alt="版本">
  <img src="https://img.shields.io/badge/Bash-Script-blue.svg" alt="Bash脚本">
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="许可证">
  <img src="https://img.shields.io/badge/Platform-Termux-orange.svg" alt="平台">
</p>

## 🌟 项目简介

Termux 工具版环境配置脚本是一个功能强大的 Bash 脚本，专为 Termux Android 终端设计。它提供了网络检测、代理管理、Git镜像优化、系统配置等一站式解决方案，极大提升了 Termux 的使用体验和开发效率。

## ✨ 核心特性

### 🌐 **网络与代理管理**
- **智能网络检测**: 自动检测局域网/公网 IP，显示归属地信息
- **三地址连通性测试**: 同时检测百度、Google、GitHub 的访问状态
- **智能代理切换**: 自动检测代理可用性，根据网络环境智能切换
- **代理配置管理**: 支持 HTTP/HTTPS 和 SOCKS5 代理，支持认证
- **延迟测试**: 测试直连和代理模式下的网络延迟

### 📦 **Git 与 GitHub 优化**
- **多镜像源支持**: gitclone.com、ghproxy.com 等多个国内镜像源
- **智能镜像选择**: 自动测试并选择最快的镜像源
- **一键镜像切换**: 支持快速切换和关闭 Git 镜像
- **GitHub PAT 配置**: 完整的 GitHub Personal Access Token 配置流程
- **Git 配置管理**: 显示和管理 Git 用户名、邮箱、别名等配置

### 🔧 **系统工具与配置**
- **Termux 命令大全**: 包含 8 大类 100+ 个常用命令
- **批量工具安装**: 一键安装开发、网络、系统等常用工具
- **缓存清理**: 智能清理 APT 缓存、临时文件、下载目录
- **配置备份恢复**: 完整配置的导入/导出功能
- **脚本安装管理**: 支持安装到启动项，开机自动运行

### 🖥️ **系统信息展示**
- **实时系统监控**: 显示 CPU、内存、存储使用情况
- **电池状态检测**: 显示电池电量、充电状态、电流信息
- **网络状态展示**: 实时显示 IP、归属地、延迟等信息
- **配置状态概览**: 显示代理、镜像、GitHub 等配置状态

### 🎯 **用户体验优化**
- **彩色交互界面**: 美观的彩色输出和进度指示器
- **智能提示符**: 命令提示符显示代理和镜像状态
- **快捷键系统**: 提供 30+ 个实用的快捷命令
- **交互式配置**: 引导式的交互配置界面
- **自动更新**: 支持脚本自动检测和更新

## 📥 安装与使用

### 环境要求
- Android 设备（需要安装 Termux）
- 网络连接（用于下载和网络功能）
- 基本的存储权限

### 快速安装

1. **克隆或下载脚本**
`# 克隆项目（如果使用代理或镜像）`
`git clone https://github.com/cc999g/termux-enhancer.git`
`cd termux-enhancer`
``
`# 或者直接下载脚本`
`curl -O https://raw.githubusercontent.com/cc999g/termux-enhancer/main/termux-enhancer.sh`
`chmod +x termux-enhancer.sh`

2. **首次运行配置**
`# 运行脚本`
`./termux-enhancer.sh`
``
`# 或使用安装到启动项`
`./termux-enhancer.sh`
`# 在交互菜单中选择安装脚本到启动项`

3. **安装到启动项（推荐）**
运行脚本后，按照提示选择安装到启动项：
- 脚本会自动安装到 `~/.termux/boot/`
- 添加到 `.bashrc` 自动加载
- 创建快捷命令 `tool`

`# 安装后，可以使用以下方式启动`
`termux-enhancer              # 快捷命令启动`
`# 或者重启 Termux 自动加载`

4. **卸载脚本**
`# 运行卸载脚本`
`~/.termux/boot/uninstall_enhancer.sh`
``
`# 或者手动移除`
`rm -f ~/.termux/boot/termux-enhancer.sh`
`rm -f ~/.termux/boot/uninstall_enhancer.sh`
`sed -i '/termux-enhancer/d' ~/.bashrc`
`unalias tool 2>/dev/null`

## 📚 详细使用指南

### 🚀 快捷命令系统

脚本安装后提供丰富的快捷命令：

| 命令类别 | 命令示例 | 功能描述 |
|---------|---------|---------|
| **代理管理** | `proxy-on` `proxy-off` | 开启/关闭代理 |
| **网络检测** | `net-check` `delay-compare` | 网络连通性测试 |
| **Git镜像** | `git-mirror-switch` `auto-mirror` | 镜像切换与测试 |
| **系统工具** | `install-tools` `clean-cache` | 工具安装与清理 |
| **配置管理** | `export-config` `import-config` | 配置备份与恢复 |
| **信息显示** | `system-info` `git-config-show` | 系统与配置信息 |

### 🔧 主要功能使用

#### 1. 网络配置与代理
`# 配置代理服务器`
`proxy-set`
``
`# 测试代理连通性`
`proxy-check`
``
`# 对比直连和代理延迟`
`delay-compare`

#### 2. Git 与 GitHub 配置
`# 自动选择最快镜像`
`auto-mirror`
``
`# 配置 GitHub Personal Access Token`
`github-pat-setup`
``
`# 查看 Git 配置状态`
`git-config-show`

#### 3. 系统工具安装
`# 批量安装常用工具`
`install-tools`
``
`# 清理系统缓存`
`clean-cache`
``
`# 查看系统信息`
`system-info`

#### 4. 配置管理
`# 导出当前配置（备份）`
`export-config`
``
`# 导入配置文件（恢复）`
`import-config`
``
`# 检查脚本更新`
`script-update`

## 🛠️ 功能详解

### 网络检测模块
- **IP检测**: 使用多个 API 获取公网 IP，显示详细归属地信息
- **延迟测试**: 支持 ping 和 curl 两种方式，提供准确延迟数据
- **连通性检查**: 并行检测国内外网站，显示详细状态和延迟

### 代理管理模块
- **智能检测**: 自动检测代理服务器可用性
- **协议支持**: 完整支持 HTTP/HTTPS 和 SOCKS5 协议
- **认证支持**: 支持用户名密码认证的代理服务器
- **全局生效**: 代理设置对 curl、wget、git 等工具全局生效

### Git 优化模块
- **镜像加速**: 国内镜像显著提升 clone 和 pull 速度
- **智能切换**: 根据网络环境自动选择最佳镜像
- **配置持久**: 镜像配置保存在 Git 全局配置中
- **速度测试**: 提供镜像速度对比测试功能

### 系统工具模块
- **分类安装**: 将工具分为基础、开发、网络、实用等类别
- **进度显示**: 安装过程显示详细进度条和状态
- **错误处理**: 安装失败的工具提供手动安装建议
- **版本验证**: 安装后显示工具版本信息

## ⚙️ 配置说明

### 配置文件位置
- 主配置文件: `~/.termux_enhancer_config`
- GitHub PAT 配置: `~/.github_pat`
- Git 凭据文件: `~/.git-credentials`
- 备份目录: `~/.termux_enhancer_backups/`
- 日志文件: `~/.termuxtool.log`

### 配置项说明
`# 代理配置`
`PROXY_PROTOCOL="http"           # 代理协议: http/socks5`
`PROXY_HOST="127.0.0.1"          # 代理服务器地址`
`PROXY_PORT="7890"               # 代理服务器端口`
`PROXY_USER=""                   # 代理用户名（可选）`
`PROXY_PASS=""                   # 代理密码（可选）`
``
`# 功能开关`
`ENABLE_BOOT_CHECK="true"        # 启用开机检测`
`ENABLE_PROGRESS_INDICATOR="true" # 启用进度指示器`
`CONFIG_TIMEOUT=10               # 配置超时时间（秒）`
`DELAY_THRESHOLD=500             # 延迟阈值（ms）`

## 🔍 命令提示符说明

脚本会修改 Termux 的命令提示符（PS1），显示以下信息：

`P 🟢 M 🟢 user@host:~/path[main]$`

- **P 🟢/P ❌**: 代理状态（绿色✅=开启，红色❌=关闭）
- **M 🟢/M ❌**: Git 镜像状态（紫色✅=开启，紫色❌=关闭）
- **user@host**: 用户名和主机名（绿色）
- **~/path**: 当前路径（蓝色）
- **[main]**: Git 分支（黄色，如果有）

## 📁 项目结构

`termux-enhancer/`
`├── termuxtool.sh          # 主脚本文件`
`├── README.md                   # 项目说明文档`
`├── version.txt                 # 版本信息文件`
`└── .github/                    # GitHub 相关配置`
`    └── workflows/              # CI/CD 工作流`

## 🚨 注意事项

1. **权限要求**:
   - 需要 Termux 存储权限（`termux-setup-storage`）
   - 网络检测需要网络权限
   - 电池信息需要 Termux-API 权限

2. **依赖工具**:
   - 脚本会自动检测并安装缺失的依赖
   - 主要依赖：curl、git、bc、awk、sed 等

3. **网络要求**:
   - 部分功能需要网络连接
   - 网络检测功能需要访问外网
   - 镜像切换功能依赖镜像站可用性

4. **兼容性**:
   - 支持 Termux 官方版本
   - 测试于 Android 8.0 及以上版本
   - 需要 Bash 4.0 及以上版本

## 🔄 更新日志

### v1.0 (最新版本)
- **新增**: Git 配置状态显示功能
- **新增**: 批量安装常用工具功能
- **新增**: 自动清理缓存功能
- **新增**: 配置导入/导出功能
- **新增**: 脚本安装/卸载功能
- **新增**: 自动测试并选择镜像功能
- **优化**: 命令提示符显示简化
- **优化**: 网络检测算法改进
- **修复**: 多个函数未定义错误
- **修复**: 颜色代码显示问题

### v0.9
- 基础网络检测功能
- 代理管理功能
- Git 镜像切换功能
- GitHub PAT 配置功能
- 系统信息显示功能

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request 来帮助改进这个项目。

1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 📄 许可证

本项目基于 MIT 许可证开源。详见 [LICENSE](LICENSE) 文件。

## 🙏 致谢

- 感谢所有 Termux 开发者和社区成员
- 感谢各镜像站提供的加速服务
- 感谢所有贡献者和用户的支持

## 📞 支持与反馈

- 提交 Issue: [GitHub Issues](https://github.com/cc999g/termux-enhancer/issues)
- 功能建议: 欢迎提出新功能建议
- 问题反馈: 遇到问题请提供详细描述和日志

---

<p align="center">
  让 Termux 更加强大，让开发更加高效！ 🚀
</p>
