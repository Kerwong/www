---
title: 关于 Maven (一)介绍入门与安装
comments: true
date: 2016-05-17 20:13:02
tags:
- Java
- Maven
- Spring
---

每次对一项新技术，都是从一个陌生名词开始的。记不起什么时候看到的 Maven  这词，觉得高大上（在IT这行混久了，一旦不学习，看什么都觉得高大上了），后来终于运用到了实践当中，问了下厂，发觉自己落伍太久了。抽个没加班的日子，把这个给梳理一下。

<!--more-->

# Maven 介绍
Maven  是 Apache  项目组下的一个跨平台的项目管理工具。
Maven  是一款**自动化构建工具**，是为了解决项目中繁琐的编译、运行单元测试、生成文档、打包、部署等工作开发的。Maven  抽象了完整的构建生命周期模型，标准化的构建过程可以避免错误和利用插件。
如果仅仅用 IDE ，一堆 jar  包依赖就会让人发狂，Maven  可以用来做依赖管理和项目信息管理，提供了中央仓库，帮助 DEV  自动下载包以及包的依赖，更可以避免同一个工程中同一个包的不同版本的重复。 可以理解为 Maven  = “自动打包器”。
Maven  提供了标准的工程目录结构，一目了然，Convention Over Configuration （约定由于配置）。
而且Maven  实现 XP  的核心价值：
1. 简单
2. 交流与反馈
3. 测试驱动开发 TDD
4. 十分钟构建
5. 持续集成 CI
6. 富有信息的工作区

要想了解一项技术，最好的方法便是实践！
<br/>

# Maven 的配置安装
> Maven 的官网 http://maven.apache.org/

基本上关于 Maven  的安装，配置，插件都能在官网上找到答案，官方文档是找资料的最好的途径。
Maven  本身的配置比较简单，日常的使用甚至完全不需要管配置，因为我用 Maven  还比较初级，所以关于 setting.xml  配置了解的还不多。本文作为整理，还是少许罗列部分。
<br/>

## 基本配置
1. 在 OS  中，需要配置环境变量，`M2_HOME = ${MAVEN_HOME}`
2. Maven  的全局配置文件为 `${MAVEN_HOME}/conf/setting.xml`
3. Maven  的用户配置文件一般位于 `~/.m2/`  目录下（~ 表示用户目录）

<br/>

## IDE 下的 Maven

IDE  下的 Maven  集成，可以参考 http://maven.apache.org/ide.html
简单来说，eclipse J2EE  版本已经自带 maven ，不带有maven  的 eclipse ，DEV  可以去 `install new software - plugin : m2eclipse` ，地址是
> http://m2eclipse.sonatype.org/sites/m2e

Jetbrain  的话，注意两项配置，一是配置 Maven Home
![](http://img.wenchao.wang/17-5-17/58590535-file_1495023435493_b17f.png "IDEA Maven 配置")

二是需要在 Runner  下的 VM option  添加一行 `-Dmaven.multiModuleProjectDirectory=$M2_HOME`
![](http://img.wenchao.wang/17-5-17/85039761-file_1495024095027_87bf.png "maven vm")
<br/>

# 开始 Maven 项目

我的 IDE  是IDEA ，我也尝试过用 eclipse  开发 maven ，基本流程都差不多，因此就拿 IDEA  的开发流程作为参考。



Step 1：File -> New -> Project... ，在左栏选择 Maven

![](http://img.wenchao.wang/17-5-17/58449633-file_1495024135848_54.png "Maven step 1")



这里可以选择 archetype ，例如常用的 maven-archetype-quickstart , maven-archetype-webapp  等。这里选择 maven-archetype-quickstart  作为学习。
<br/>

Step 2：输入 GroupId ，ArtifactId ，Version ，这三个字段，同时也是 maven  包坐标的三个字段，指向了唯一一个包。

![](http://img.wenchao.wang/17-5-17/81784400-file_1495024177606_14396.png "Maven step 2")



Step 3（可选）：第一次创建 Maven  项目的话，需要配置选择 Maven  版本

![](http://img.wenchao.wang/17-5-17/49799708-file_1495024207143_e6ed.png "Maven step 3")

在 《Maven 实战》一书中，作者强调了不推荐使用 IDE  自带的 Maven ，
因为一是 IDE Bundled Maven  版本可能不稳定；
二是除了 IDE ，可能还会用到 Maven  的命令行，为了保证 Maven  工程的一致，建议使用官网下载的 Maven

至此一个 Maven  项目已经创建完毕。但现在的 Maven  项目还什么都不能做，还需要了解 Maven  的目录结构、生命周期、POM  配置才行。
<br/><br/>

# 参考资料
[1]《Maven 实战》（第1版），许晓斌著
[2] Maven Central Repository：http://search.maven.org/，可以在这里找相关包，查找包的版本等。
[3] Maven 的官网 http://maven.apache.org/，关于 Maven 的实用资料