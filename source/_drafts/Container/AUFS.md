---
title: 剖析 Docker 原理系列（）—— AUFS 文件系统
comments: true
date: 2017-04-16 20:57:18
tags:
- SQL
- Reading
---



Docker 是分层的

底层依赖于内核的文件系统

要做到隔离，依赖于 UFS 等





AUFS 是 UnionFS (Union File System) 的升级，UnionFS 是为了实现将不同物理位置的文件目录，统一挂载到同一目录下进行使用的