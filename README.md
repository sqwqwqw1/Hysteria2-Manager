# Hysteria2 一键安装/卸载脚本

作者：Yaodo  
支持：Ubuntu / Debian (x86/AMD)

## 功能

- 一键安装 Hysteria2 服务端  
- 自动获取服务器公网 IP  
- 自动生成随机 UDP 端口（9000–19999，可手动输入）  
- 自动生成随机密码（可自定义）  
- 自动生成自签 TLS 证书  
- systemd 服务开机自启  
- 支持 UFW 自动放行 UDP 端口  
- 一键卸载 Hysteria2  

## 脚本地址

```
https://raw.githubusercontent.com/sqwqwqw1/Hysteria2-Manager/refs/heads/main/hysteria-manager.sh
```

## 安装命令

通过 GitHub Raw URL 一键安装：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sqwqwqw1/Hysteria2-Manager/refs/heads/main/hysteria-manager.sh) install
```

或者使用 wget：

```bash
bash <(wget -qO- https://raw.githubusercontent.com/sqwqwqw1/Hysteria2-Manager/refs/heads/main/hysteria-manager.sh) install
```

安装过程中，脚本会提示：

- Hysteria UDP 端口（默认随机生成）  
- 密码（默认随机生成）  

安装完成后，脚本会输出：

- 服务器公网 IP  
- UDP 端口  
- 密码  

## 卸载命令

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sqwqwqw1/Hysteria2-Manager/refs/heads/main/hysteria-manager.sh) uninstall
```

卸载时，脚本会停止服务、删除配置文件和可执行文件，可选择删除 UFW 放行端口。  

## 查看服务状态

```bash
systemctl status hysteria-server
ss -ulnp | grep <端口号>
journalctl -u hysteria-server -f
```

> `Active: active (running)` 表示服务运行正常  

## 客户端配置

- 服务器 IP：脚本输出的公网 IP  
- 端口：脚本输出的 UDP 端口  
- 密码：脚本输出的密码  
- TLS：开启，自签证书  
- SNI：使用 IP  

客户端支持：Windows / macOS / Linux / iOS / Android  

## 注意事项

- VPS 防火墙或安全组必须放行 UDP 端口  
- TLS 为自签证书，客户端需允许自签  
- 脚本需 root 权限执行  
