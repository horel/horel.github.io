---
title: "OpenWRT指北"
comment: false
weight: 0
date: 2025-01-14T22:55:35+08:00
# 由 enableGitInfo 替代
# lastmod: 14000-01-01
# draft: false
# math: true
# featuredImage: ""
# featuredImagePreview: ""
# keywords: [""]
categories: ["网络"]
tags:
  - 网络
---

## 设备选择
因偶然的需求，想了解一下OpenWRT。

首先是设备的选择，因软路由价格较高，盯上了硬路由然后刷OpenWRT。

从[OpenWRT](https://openwrt.org/toh/start)的官网查看有哪些设备支持刷固件，有成熟的解决方法。

在使用MT7981B的基础上，本着能省就省的原则，选择了设备[JCG Q30 Pro](https://openwrt.org/toh/jcg/q30_pro)。

## 刷机教程
1. 查看Kevin.MX大佬写的免拆机版：[捷稀 JCG Q30 Pro 刷机说明 - 免拆版](https://mary.kevinmx.top/default/JCG-Q30-Pro-Neo.html)
2. 如果看不懂的，也有视频教程：[7981真不错，一百块的WIFI6路由器捷稀 JCG Q30 PRO 刷机与体验](https://www.bilibili.com/video/BV1Cx4y1f7EE/?share_source=copy_web&vd_source=a071843196469a855cb50fdc0a5f6d5d)
3. 还可以查看OpenWRT的官网给出的：[JCG Q30 Pro](https://openwrt.org/toh/jcg/q30_pro)

## 第一次刷机
很简单的安装上面的教程就完成了刷机，简单试了试OpenWRT，还挺有趣的，很精简的一个Linux。

但让我没想到的是，事情突然有了转折......

在我想重启想尝试刷入另一个固件的时候，发现uboot出问题了，又因为手贱给折腾成砖了......

但运气比较好的是我搜索资料发现MT7981B的砖都可以救过来，遂下手一个CH340G

## 第二次刷机
又等了好几天，CH340G到了之后，又可以折腾OpenWRT路由器了

按照教程操作：
1. [MediaTek Filogic 系列路由器串口救砖教程](https://www.cnblogs.com/p123/p/18046679)
2. [路由器救砖教程涵盖几乎所有7981/7986路由器适合小白！](https://www.bilibili.com/video/BV1uaUJYeENm/?share_source=copy_web&vd_source=a071843196469a855cb50fdc0a5f6d5d)

至此，OpenWRT终于刷好了

## 简单设置
### 登录
连接WIFI，immortalwrt默认无密码，访问 192.168.1.1

### 密码
默认无登陆密码，需要自己设置

### 主题
在软件包中搜索luci-theme-argon，安装并设置

### 其他软件包
- tailscale
- wakeonlan

