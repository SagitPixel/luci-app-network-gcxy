# luci-app-network-gcxy

一个专为 OpenWrt 设计的校园网自动认证插件，基于 Lua 和 Shell 实现。(本插件暂未测试是否可用，预计2026.3进行实机测试)

## 🌟 功能特点
- **LuCI 图形化界面**：支持直接在路由器 Web 页面填写手机号和配置。
- **持久化运行**：通过 `procd` 守护进程实现，脚本挂掉自动重启。
- **智能监控**：定时检测网络连通性，断网自动触发重新认证。
- **自动获取信息**：自动提取 WAN 口的 IP 和 MAC 地址，无需手动配置。
- **日志记录**：详细的日志输出，方便调试认证过程。

## 🛠️ 安装方法

### 方式一：作为 OpenWrt Feeds 安装 (推荐)
1. 进入你的 OpenWrt 源码目录。
2. 在 `feeds.conf.default` 文件末尾添加：
   ```text
   src-git gcxy [https://github.com/SagitPixel/luci-app-network-gcxy.git](https://github.com/SagitPixel/luci-app-network-gcxy.git)
   ```
更新并安装 Feed：
  ```text
  ./scripts/feeds update gcxy
  ./scripts/feeds install -a -p gcxy
  ```
在 make menuconfig 中选中： Network -> network-gcxy

方式二：手动放入 Package 目录
将本项目整个文件夹克隆到 package/network-gcxy：
  ```text
  cd package
  git clone [https://github.com/SagitPixel/luci-app-network-gcxy.git](https://github.com/SagitPixel/luci-app-network-gcxy.git)
  ```
回到源码主目录运行 make menuconfig 勾选即可。

📖 使用说明
进入 OpenWrt 后台，点击 “网络” -> “校园网认证”。

勾选 “启用”。

填写你的 “手机号”（插件会自动拼接为 g+手机号 格式）。

点击 “保存并应用”。

调试：可以通过 cat /var/log/network_gcxy.log 查看实时认证结果。

## 🤝 致谢
- **核心逻辑**：参考自 [xiananrain/gcxy](https://github.com/xiananrain/gcxy)。
- **AI 辅助**：本项目开发过程中得到了 **Google Gemini** 的全程技术支持，涵盖了从 LuCI 界面架构到Makefile 编写。


📄 许可证
MIT License
