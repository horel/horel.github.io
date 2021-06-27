---
title: 编译DOOM3
comment: false
categories:
  - [二进制玄学]
tags:
  - Linux
  - 编译
date: 2021-06-20 16:42:27
cover:
---

# 编译DOOM3

ID SoftWare公司的经典作品，DOOM3

~~其实是因为我是约翰·卡马克的粉丝~~{.danger}

![约翰·卡马克](https://tva4.sinaimg.cn/large/008ieO5lly8gqmb5tqfs4j30go093wfi.jpg "约翰·卡马克")

直接选择编译DOOM3-BFG了，恰好Github上有大佬专门写了这部分的引擎，[RBDOOM-3-BFG](https://github.com/RobertBeckebans/RBDOOM-3-BFG)，就直接拿来编译了

然后就吃了不同发行版之间的亏......

> ArchLinux要安装以下的依赖

```bash
sudo pacman -S sdl2 cmake openal ffmpeg
```

但是因为SDL2官方有两种打包方式，显然ArchLinux采用了另一种让，所以我在编译时一直找不到SDL......

> 因此修改以下CMakeLists.txt

```cmake
diff --git a/neo/CMakeLists.txt b/neo/CMakeLists.txt
index 1a36eef..ba149df 100644
--- a/neo/CMakeLists.txt
+++ b/neo/CMakeLists.txt
@@ -1599,8 +1599,8 @@ else()
 
 		if(SDL2)
 			find_package(SDL2 REQUIRED)
-			include_directories(${SDL2_INCLUDE_DIRS})
-			set(SDLx_LIBRARY ${SDL2_LIBRARIES})
+			include_directories(SDL2::SDL2)
+			set(SDLx_LIBRARY SDL2::SDL2)
 		else()
 			find_package(SDL REQUIRED)
 			include_directories(${SDL_INCLUDE_DIR})
```

编译完成后，将游戏的资源文件base放入build文件夹

> 注意，运行游戏时，会在~/.local/share/rbdoom3bfg下生成游戏文件

如果重新编译使用记得清除旧游戏生成文件

> vulkan支持需要git clone ----recursive

> 随后我创建了它的桌面图标

```bash
vi .local/share/applications/DOOM3.desktop
```

```bash
[Desktop Entry]
Name = DOOM-3-BFG
Exec = /home/limbo/Documents/aur/RBDOOM-3-BFG/DOOM3/build/RBDoom3BFG
Encoding = UTF-8
Comment = DOOM-3-BFG
Type = Application
Terminal=false
```



