---
title: 关于 Maven (二)深入分析
comments: true
date: 2016-05-17 20:40:54
tags:
- Java
- Maven
- Spring
---



Maven  项目一般采用标准的工程目录，所有文件也应该按照约定放置。通过 IDEA  生成的 Maven  项目，往往目录是不完整的，因此需要自行创建。
> 官方关于标准目录的介绍 http://maven.apache.org/guides/introduction/introduction-to-the-standard-directory-layout.html

<!--more-->

```
/
├────pom.xml					Maven 主要的配置文件
├────src/ 
│      ├────main/				项目主体目录，与之相对的是 test/ 目录
│      │      ├────java/		存放项目 Java 源代码的目录
│      │      ├────resources/	所需资源文件存放目录，一般多存放 xml 配置等
│      │      ├────webapp/		Web 工程目录，存在 WEB-INF/, web.xml 等
│      │      └────filters/		资源过滤文件目录 
│      ├────test/
│      │      ├────java/		测试代码目录
│      │      ├────resources/   
│      │      └────filters/
│      ├────it/					Integration Tests (primarily for plugins)
│      ├────assembly/			Assembly descriptors
│      └────site/				与 Site 相关资源目录
└────target/					输出目录根
      ├────classes/
      ├────test-classes/
      └────site/
```

以上为一般项目必须的以外，目录视具体项目而定，并非必有。

<br/>

# Maven 生命周期

Maven  是一个构建工具，在 Maven  出现之前，构建便一直存在。但 Maven  的出现，将项目构建抽象成了一个标准的模型（即项目的生命周期），通过 Maven  生命周期的管理，项目的清理、初始化、编译、测试、打包、部署都容易了很多。

Maven  的生命周期分为 clean （清理项目），default （构建），site （建立项目站点）三个独立部分。

Maven 生命周期：
![Maven 生命周期](http://nutslog.qiniudn.com/16-12-22/74202232-file_1482338418351_166d7.png "Maven 生命周期")

以下为摘自 《Maven 实战》中关于生命周期的描述：

| Maven 生命周期 |                         |                                          |
| ---------- | ----------------------- | ---------------------------------------- |
| clean      | pre-clean               | 执行一些清理前需要完成的工作                           |
|            | clean                   | 清理上一次构建生成的文件                             |
|            | post-clean              | 执行一些清理后需要完成的工作                           |
| default    | validate                |                                          |
|            | initialize              |                                          |
|            | generate-sources        |                                          |
|            | process-sources         | 处理项目主资源文件。src/main/resources 目录的内容进行变量替换等操作后，复制到项目输出的主 classpath 目录中 |
|            | generate-resources      |                                          |
|            | process-resources       |                                          |
|            | compile                 | 编译项目的主源码。一般是编译 src/main/java 目录下的 Java 文件至项目输出 classpath 目录 |
|            | process-classes         |                                          |
|            | generate-test-sources   |                                          |
|            | process-test-sources    | 处理项目测试资源文件。一般是对 src/test/resources 目录内容进行变量替换等工作后，复制至测试 classpath 目录中 |
|            | generate-test-resources |                                          |
|            | process-test-resources  |                                          |
|            | test-compile            | 编译项目的测试代码。一般是编译 src/test/java 目录下的 Java 文件至项目输出的测试 classpath 目录中 |
|            | process-test-classes    |                                          |
|            | test                    | 使用单元测试框架运行测试，测试代码不会被打包或部署                |
|            | prepare-package         |                                          |
|            | package                 | 接受编译好的代码，打包成可发布的格式，如 jar                 |
|            | pre-integration-test    |                                          |
|            | integration-test        |                                          |
|            | post-integration-test   |                                          |
|            | verify                  |                                          |
|            | install                 | 将包安装到 Maven 本地仓库。供本地其他 Maven 项目使用        |
|            | deploy                  | 将最终的包复制到远程仓库，供其他开发和 Maven 项目使用           |
| site       | pre-site                | 执行一些在生成项目站点之前需要完成的工作                     |
|            | site                    | 生成项目站点文档                                 |
|            | post-site               | 执行一些在生成项目站点之后需要完成的工作                     |
|            | site-deploy             | 将生成的项目站点发布到服务器                           |

> 官网关于 LifeCycle 的详解 http://maven.apache.org/guides/introduction/introduction-to-the-lifecycle.html

在执行 Maven  命令时，如 mvn test , 则在 default  阶段，test  之前的所有操作都将被执行，即上表中从 validate  至 test  之间所有的命令都将被执行。而非 default  段的命令，包括 clean  和 site  段，由于与 default  段是相互独立的，所以不被执行。

<br/>

# Maven 的坐标与依赖

在 POM  文件中，通过 Maven  的坐标来确定一个包。
例如以下为描述一个依赖的完整形态：
```XML
<dependency>
    <groupId>org.eclipse.jetty</groupId>
    <artifactId>jetty-servlets</artifactId>
    <version>7.4.0.v20110414</version>
    <scope>provided</scope>
    <classifier>jdk15</classifier>
    <type>jar</type>
    <optional>true</optional>
    <exclusions>
        <exclusion>
            <groupId>org.eclipse.jetty</groupId>
            <artifactId>jetty-client</artifactId>
        </exclusion>
    </exclusions>
</dependency>
```

其中：
- groupId : 定义当前 Maven  项目对应的实际项目。首先，Maven  项目和实际项目不是一对一的关系，例如 springframework  这一实际项目下，会有 spring-core ，spring-context  等诸多子项目；其次，groupId  不应该对应项目隶属的组织或公司，因为一个组织或公司下，会有很多实际项目；最后 groupId  的表示方式与 Java  包名的表示方式类似，例如 com.test.xxx
- artifactId : 该元素定义实际项目中的一个 Maven  项目，推荐做法使用实际项目名称作为 artifactId  的前缀。
- version : 该元素定义了 Maven  项目当前所处的版本。
- packaing （可选）: 该元素定义了 Maven  项目的打包方式。如 jar ，war  包，其中 jar  为 Maven  的默认值
- type （与 packaging  相对）: 依赖的类型，默认为 jar
- scope : 依赖的范围，依赖范围用来控制依赖与三种 classpath  （编译 classpath ，测试 classpath ，运行 classpath ）的关系，依赖范围有

| Scope       | CLASSPATH 编译 | CLASSPATH 测试 | CLASSPATH 运行                             | 例子          |
| ----------- | ------------ | ------------ | ---------------------------------------- | ----------- |
| compile（默认） | Y            | Y            | Y                                        | spring-core |
| test        |              | Y            |                                          | JUnit       |
| provided    | Y            | Y            |                                          | Servlet-api |
| runtime     |              | Y            | Y                                        | JDBC驱动      |
| system（慎用）  | Y            | Y            | 本地绑定，Maven 仓库外的类库文件，使用 system 范围的依赖时必须通过 systemPath 元素显式指定依赖文件的路径 |             |
| import      |              |              |                                          |             |

- classifier （插件生成，不可定义）: 该元素用来帮助定义构建输出一些附属构件。附属构件指文档或源代码等，通过插件帮助生成。
- optional : 可选依赖，如创建的项目为 A，为在 A 项目的 POM.xml  文件中指明了可选依赖于 B 包，那么依赖于 A 的项目将不会依赖于 C。根据单一职责性原则，应尽可能不出现 optional  标签。

![](http://nutslog.qiniudn.com/17-5-17/36867448-file_1495026969419_7912.png)

以上 groupId ，artifactId ，version 三项为必填项。

<br/>

# Maven 的仓库

一般而言，DEV  可以直接选用中央仓库来为项目提供包的支持，但也可以在组织内部搭建私有的中央库，这么做的目的一是访问中央库需要外部网络，二是需要管理发布一些组织内部私有的包。
由于大多数 DEV  并不会也没必要去管理一个私有的库，因此，待之后有需求时再学习下私有库的搭建了。
![](http://nutslog.qiniudn.com/17-5-17/51634541-file_1495026996531_18271.png)

- 本地仓库指保存在 .m2/  目录下的库
- 中央仓库指默认的远程仓库，可以在 setting.xml  中配置，也可以在项目 pom.xml  文件中配置。
```XML
<repositories>
  <repository>
    <id>jdk14</id>
    <name>Repository for JDK 1.4 builds</name>
    <url>http://www.myhost.com/maven/jdk14</url>
    <layout>default</layout>
    <snapshotPolicy>always</snapshotPolicy>
  </repository>
</repositories>
```

- 私服，指组织内部局域网搭建的仓库，当私服不存在该构件时，会向远程中央仓库请求。

以上对 Maven  进入了深入的介绍，在这篇里多次提到了 pom.xml  这个 Maven  项目最重要的文件，那么也该看看这个的全貌了。

<br/><br/>

# 参考资料
- 《Maven 实战》（第1版），许晓斌著