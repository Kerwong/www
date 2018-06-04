---
title: '聊聊几种常用的 Java 构建工具: Maven, Ant+ivy 与 Gradle 之比较'
comments: true
date: 2015-12-20 17:21:31
tags:
- Java
- Maven
- Ant
- ivy
- Gradle
---


在前公司开发时，为公司项目引入了 Maven，摆脱了无止境的 jar 管理，方便了工程打包和发布。当时的项目，由于我拥有着绝对的主导权，并且项目本身工程量不大。Maven 运行的非常好，迁移转交给同事，基本上能克服原有的复杂的环境配置和依赖管理，实现顺利的交接。
近了新的公司，发现这边对于项目构建，采用的是 Ant+ivy 方案，这么选择固然有其历史原因，作为后来者，想要改变原有的技术方案，是十分困难的（由于变更风险巨大，基本不可能实现），因此，我不得不去学习这种新的构建方案。

之前仅学习过使用过 Maven，在了解了 Ant 后发现了其诸多的优点。由于对 Maven、Ant+ivy、Gradle 这几种构建又存在着一些困惑，故在此做一个梳理，区分下优劣，仔细了解下应用场景。
几种构建方法，**没有绝对的好坏之分，必须要针对引用场景具体问题具体分析**。
<!--more-->

# 构建工具的介绍
在开始介绍下面三种工具前，先让我来谈谈**构建**。
在编程开发中，除了 coding 以外，距离项目发布上线还需要许多步骤。对于 `C/C++` 而言，从源代码到可执行文件，需要将 `.h`, `.cpp` 文件预处理->编译和优化->生成目标文件文件 `.o`->链接->生成可执行文件 `.exe` 或静态、动态链接库。对于 `Java` 而言，则是编译`JVM`可识别的成字节码`.class`文件。生成可执行文件或者字节码后，下一步或有单元测试、集成测试，然后是打包发布等过程。在这个过程中，还可能涉及文件、目录的管理、依赖的管理等等。这些所有的步骤，就是**构建**。
这个过程是一个重复化程度很高的工作，于是大神们为了省心省力，便开发了构建工具，用于专门管理包括但不限于编译、打包、发布、测试、集成等。
在 C/CPP 独霸的时代，只有 Make 这一种构建工具。至今其仍然是诸多 C/C++ 项目的首选构建工具，只不过通过不断改进，IDE 已经能帮助我们省去了大量编写 Makefile 文件的工作。
> Make 是由一个名为 Makefile 的脚本文件驱动，该文件使用 Make 自定义的语法格式。基本组成部分为一系列的规则（Rules），而每一条规则又包括目标（Target）、依赖（Prerequisite）和命令（Command）。 
> ——摘自《Maven 实战》1.2.3节

一个典型的 Makefile 文件如下，摘自 lua 项目：
```makefile
# Makefile for installing Lua
# See doc/readme.html for installation and customization instructions.

# == CHANGE THE SETTINGS BELOW TO SUIT YOUR ENVIRONMENT =======================

# Your platform. See PLATS for possible values.
PLAT= none

# Where to install. The installation starts in the src and doc directories,
# so take care if INSTALL_TOP is not an absolute path. See the local target.
# You may want to make INSTALL_LMOD and INSTALL_CMOD consistent with
# LUA_ROOT, LUA_LDIR, and LUA_CDIR in luaconf.h.
INSTALL_TOP= /usr/local
INSTALL_BIN= $(INSTALL_TOP)/bin
INSTALL_INC= $(INSTALL_TOP)/include
INSTALL_LIB= $(INSTALL_TOP)/lib
INSTALL_MAN= $(INSTALL_TOP)/man/man1
INSTALL_LMOD= $(INSTALL_TOP)/share/lua/$V
INSTALL_CMOD= $(INSTALL_TOP)/lib/lua/$V

# How to install. If your install program does not support "-p", then
# you may have to run ranlib on the installed liblua.a.
INSTALL= install -p
INSTALL_EXEC= $(INSTALL) -m 0755
INSTALL_DATA= $(INSTALL) -m 0644

... ... ...

# Lua version and release.
V= 5.2
R= $V.3

# Targets start here.
all:	$(PLAT)

$(PLATS) clean:
	cd src && $(MAKE) $@

test:	dummy
	src/lua -v
```

在 Java 领域，比较著名的构建工具有：
- Maven
- Ant，以及与 ivy 结合
- Gradle
- 其它，例如Hudson、Jenkins 等

下面，便来介绍下 Maven、Ant 以及 Gradle

<br/>

## Maven
![Maven](http://nutslog.qiniudn.com/16-12-21/5027494-file_1482291248230_a5fb.jpg?imageView2/2/w/300)
学习 Maven 的主要是通过研读许晓斌先生著的《Maven 实战》，此书对 Maven 的知识框架介绍的较为仔细，值得看一看。
 > Maven 能帮助我们自动化构建过程，从清理、编译、测试到生成报告，再到打包和部署。 
 > ——摘自《Maven 实战》1.1.2 节

Maven 的优点：
 - 跨平台
 - 将构建过程（清理、编译、安装、打包、部署等）抽象为统一的生命周期，无须为此操心，避免了犯错
 - 强调约定，定义了统一的项目目录结构，降低了学习成本
 - 采用统一的中央库，迁移和部署工程时，无须整理一大堆依赖项，而统一自动从中央库中获取。减少了工程大小，方便统一版本
 - 提供了大量针对具体生命周期的插件。例如单元测试框架

缺点：
 - 依赖管理不能很好的处理相同库文件不同版本间冲突
 - 因为抽象了统一的生命周期，自由度不高。需要定制化目标困难
 - XML 作为 Maven 的配置文件，一来由于 Maven 的约定，XML 格式受限，灵活性差，二来会随着项目的增长，配置文件变得越来越大

<br/>
## Ant
![Ant](http://nutslog.qiniudn.com/16-12-21/16206312-file_1482291247993_8dbc.png?imageView2/2/w/300)
熟悉 make 的人，理解 Ant 应该不难。Ant 功能上与 make 极为类似，区别在于 Ant 大多用于 Java 的开发和构建，并在 make 基础上克服了 make 的一些缺陷。
> Ant是纯Java语言编写的，所以具有很好的跨平台性。操作简单。Ant是由一个内置任务和可选任务组成的。Ant运行时需要一个XML文件(构建文件)。 Ant通过调用target树，就可以执行各种task。每个task实现了特定接口对象。
> ——摘自[百度百科 Apache Ant 条目](http://baike.baidu.com/item/apache%20ant)

Ant 的优点：
- Ant 由由纯 Java 语言编写，可跨平台
- Ant 配置文件由 XML 编写，并且只定义了基础的格式，结构清晰、灵活性高
- 学习曲线平缓，易于上手
- 经过发展，逐渐支持各类插件，使用更方便
- 与 ivy 配合后，可解决依赖管理问题

缺点：
- Ant 的层次化的 XML 配置文件，不适合于过程化的描述
- 同 Maven 一样，XML 配置文件会随着项目的增长，变的异常庞大

<br/>
## Gradle
![Gradle](http://nutslog.qiniudn.com/16-12-21/91996412-file_1482291248119_8bf3.png?imageView2/2/w/300)
Gradle 是我最不熟悉的构建工具了，是一个后起之秀，但做工程的都懂的，喜欢用老古董，`╮(╯_╰)╭`
Gradle 结合了前两者的有点，并在其基础上做了很多改进。

> Gradle是一个基于Apache Ant和Apache Maven概念的项目自动化建构工具。它使用一种基于Groovy的特定领域语言(DSL)来声明项目设置，抛弃了基于XML的各种繁琐配置。
面向Java应用为主。
> 当前其支持的语言限于Java、Groovy和Scala，计划未来将支持更多的语言。
>
> Gradle 的优点：
> - Gradle 对多工程的构建支持很出色，工程依赖是 Gradle 的第一公民。
> - Gradle 支持局部构建。
> - 支持多方式依赖管理：包括从 Maven 远程仓库、Nexus 私服、ivy 仓库以及本地文件系统的 jars 或者 dirs
> - Gradle 是第一个构建集成工具，与Ant、Maven、ivy 有良好的相容相关性。
> - 轻松迁移：Gradle 适用于任何结构的工程，你可以在同一个开发平台平行构建原工程和 Gradle 工程。通常要求写相关测试，以保证开发的插件的相似性，这种迁移可以减少破坏性，尽可能的可靠。这也是重构的最佳实践。
> - Gradle 的整体设计是以作为一种语言为导向的，而非成为一个严格死板的框架。
>
> ——摘自[百度百科 Gradle 词条](http://baike.baidu.com/item/gradle)

Gradle 缺点：
- 过于灵活。强调约定优于配置，虽然定义了生命周期，但并非强制，可轻易定制化。这使得一旦约定被突破，可能造成巨大破坏
- 相对于人尽皆知的 XML，Gradle 的配置还需要学习一门新的语言——Groovy，对于想简易使用构建工具的程序员而言，得好好考虑下投入与产出了

<br/>
# 各构建工具的比较

|  |  Make | Ant | Maven | Gradle |
| --- | --- | --- | --- |
| 跨平台 | × | √ | √ | √ |
| 学习曲线 | 一般 | 平缓 | 基础功能平缓，高级功能陡峭 | 不考虑 Groovy 的学习成本，介于 Ant 与 Maven 之间 |
| 配置文件类型 | Makefile | XML | XML | Groovy |
| 依赖管理 | 不支持 | 需与 ivy 配合 | 支持，提供中央库 | 支持，可集成 ivy 或 Maven 仓库 |
| 灵活性 | 高 | 高 | 低 | 高 |
| 执行效率 | ？ | ？ | ？ | ？ |
| 社区支持 | 一般 | 好 | 好 | 好 |
| 使用范围 | C/C++ 事实上的构建标准 | 中 | 最广泛，事实上的 Java 构建标准 | 低，但上升迅速 |
| 构建生命周期 | 未定义 | 未定义 | 较为简单，不可定制 | 较 Maven 更复杂，可定制 |

Maven 生命周期：
![Maven 生命周期](http://nutslog.qiniudn.com/16-12-22/74202232-file_1482338418351_166d7.png "Maven 生命周期")
Gradle 生命周期：
![Gradle 生命周期](http://nutslog.qiniudn.com/16-12-22/15119864-file_1482337176102_14757.png "Gradle 生命周期")

<br/><br/>

# 参考资料
[1] Java Build Tools: Ant vs Maven vs Gradle, https://technologyconversations.com/2014/06/18/build-tools/ 
[2]《Maven 实战》，许晓斌著
[3] 百度百科 Apache Ant 条目，http://baike.baidu.com/item/apache%20ant
[4] Gradle入门系列（1）：简介 http://blog.jobbole.com/71999/
[5] gradle替代maven https://my.oschina.net/enyo/blog/369843
[6] 百度百科 Gradle 条目，http://baike.baidu.com/item/gradle
[7] Gradle 官网，https://gradle.org/
[8] Maven 实战（六）——Gradle，构建工具的未来？，http://www.infoq.com/cn/news/2011/04/xxb-maven-6-gradle

