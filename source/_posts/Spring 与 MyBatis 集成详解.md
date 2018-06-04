---
title: 'Spring 与 MyBatis 集成详解'
comments: true
date: 2016-10-14 15:35:47
tags:
- Spring
- MyBatis
---

MyBatis 是介于 JDBC 与 Hibernate 之间的半 ORM 应用框架，在 Spring 开发中占有很重要的地位。
此文对此做简要的总结。

> MyBatis 是支持定制化 SQL、存储过程以及高级映射的优秀的持久层框架。MyBatis 避免了几乎所有的 JDBC 代码和手动设置参数以及获取结果集。MyBatis 可以对配置和原生Map使用简单的 XML 或注解，将接口和 Java 的 POJOs(Plain Old Java Objects,普通的 Java对象)映射成数据库中的记录。
> 
> —— 摘自 [MyBatis 中文官网](http://www.mybatis.org/mybatis-3/zh/)


<!--more-->


# Spring 与 MyBatis 的集成

MyBatis 与 Spring 的集成思路，总共有以下几个步骤：

1. 引入 MyBatis 与 Spring 框架相关的包，数据库驱动的包，可引入数据库连接池、日志、测试相关包
2. 配置XML，包括数据源 DataSource （用于指定数据库连接地址、账号、密码等数据库配置）和 SqlSessionFactory （用于指定 MyBatis 自动载入的 `*Mapper.xml`）
3. 编写 Entity 类，用来存储数据库查询返回数据，一般而言，成员变量对应数据库表字段名，仅提供 `getter/setter` 方法
4. 编写 Mapper 接口 与 `*Mapper.xml`，Mapper 接口 指定操作名，并规定好传入参数，`*Mapper.xml` 为数据库操作的 SQL ，id 需要与 Mapper 接口 一致
5. 创建数据库，编写服务，测试

<br/>

## 从 Maven 引入 jar 包

在 Maven 项目中的 `pom.xml` 文件增加以下依赖。项目一般还需要增加 log 日志模块、junit 测试模块等，在此 pom.xml 不再赘述。

```xml
<dependencies>
    <!-- Maven Lib -->
    <dependency>
        <groupId>org.springframework</groupId>
        <artifactId>spring-jdbc</artifactId>
        <version>${spring.version}</version>
    </dependency>

    <!-- MyBatis -->
    <dependency>
        <groupId>org.mybatis</groupId>
        <artifactId>mybatis</artifactId>
        <version>3.4.1</version>
    </dependency>
    <dependency>
        <groupId>org.mybatis</groupId>
        <artifactId>mybatis-spring</artifactId>
        <version>1.3.0</version>
    </dependency>

    <!-- 连接池 -->
    <dependency>
        <groupId>c3p0</groupId>
        <artifactId>c3p0</artifactId>
        <version>0.9.1.2</version>
    </dependency>

    <!--  mysql driver -->
    <dependency>
        <groupId>mysql</groupId>
        <artifactId>mysql-connector-java</artifactId>
        <version>5.1.39</version>
    </dependency>
</dependencies>
```
<br/>

## 创建数据库环境

因为 MyBatis 框架是解决持久化或者说数据库的问题，因此我们需要配置一下数据库环境。

```SQL
DROP TABLE IF EXISTS `t_user`;
CREATE TABLE `t_user` (
	`id` INT(12) NOT NULL AUTO_INCREMENT,
	`name` VARCHAR(255) NOT NULL,
	`age` INT(4) DEFAULT 0,
	`gender` INT(2),
	PRIMARY KEY(`id`)
) ENGINE=INNODB DEFAULT CHARSET=utf8;
```

<br/>

## 配置 sqlSessionFactory 与 DataSource

要使用 MyBatis ，至少需要一个 `SqlSessionFactoryBean` 是用于创建 `SqlSessionFactory` 的。要配置这个 Factory bean ，放置下面的代码在 Spring 的 XML 配置文件中。我在配置时，将数据库相关的配置都创建了一个独立的 XML 配置文件，然后在 Spring 主配置文件中通过 import 引用。

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd">

    <!-- mysql data source -->
    <bean id="dataSource" class="com.mchange.v2.c3p0.ComboPooledDataSource" destroy-method="close" lazy-init="false">
        <property name="driverClass" value="${jdbc.driverclass}"/>
        <property name="jdbcUrl" value="${jdbc.url}"/>
        <property name="user" value="${jdbc.username}"/>
        <property name="password" value="${jdbc.password}"/>
        <property name="idleConnectionTestPeriod" value="60"/>
        <property name="testConnectionOnCheckout" value="false"/>
        <property name="initialPoolSize" value="2"/>
        <property name="minPoolSize" value="5"/>
        <property name="maxPoolSize" value="50"/>
        <property name="acquireIncrement" value="1"/>
        <property name="acquireRetryAttempts" value="1"/>
        <property name="maxIdleTime" value="6000"/>
        <property name="maxStatements" value="0"/>
    </bean>

    <!-- SqlSessionFactory -->
    <bean id="sqlSessionFactory" class="org.mybatis.spring.SqlSessionFactoryBean">
        <property name="dataSource" ref="dataSource"/>
        <!-- Mapper文件存放的位置，当Mapper文件跟对应的Mapper接口处于同一位置的时候可以不用指定该属性的值 -->
        <property name="mapperLocations" value="classpath*:sqlmap/*.xml"/>
    </bean>

    <!-- DAO Mapper -->
    <bean class="org.mybatis.spring.mapper.MapperScannerConfigurer">
        <property name="annotationClass" value="org.springframework.stereotype.Repository" />
        <!-- 扫描器开始扫描的基础包名，支持嵌套扫描 -->
        <property name="basePackage" value="com.test.dao.mapper" />
    </bean>
</beans>
```

以上是 `my-db.xml` 配置文件，主要分为三部分:

1. `datasource` ，数据源，与数据库连接相关，配置数据库的地址、账户、密码，一些配置等等，从`jdbc.properties` 文件中载入。关于 Spring 如何载入 properties 文件如何实现，不在这篇文章赘述了。
2. `sqlSessionFactory` ，数据库会话工厂。从 `*Mapper.xml` 中文件自动载入
3. Mapper 类 ，在此配置中采用 Scanner 方式，自动从 mapper 包内载入 mapper 类。

<br/>

## 调用 MyBatis 框架

### 创建 Entity，映射 Database 表（或有）

在 entity 包中创建实体，对应 t_user 表 的返回。成员变量一般与数据库表字段名一一对应，成员方法仅提供 `getter/setter` 方法。

实体类不是必须的，MyBatis 提供将数据库返回简单的映射到 Map 或 HashMap 结构中，而非 POJO 中。

```java
/**
 * t_user 表实体
 */
public class User  implements Serializable {
    private int id;
    private String name;
    private int age;
    private int gender;

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public int getAge() { return age; }
    public void setAge(int age) { this.age = age; }
    public int getGender() { return gender; }
    public void setGender(int gender) { this.gender = gender; }
}
```
<br/>

### 创建 DAO/Mapper

在 `dao.mapper` 包内创建 `UserMapper` 接口 ，并添加 `@Repository` 注解

```Java
@Repository
public interface UserMapper {
    public List<User> findUserById(int id);
    public Integer insertUser(User user);
}
```

对应具体数据库的方法，例如插入用户、通过 id 查找用户。每次需要定义一个数据库操作，就在 Mapper 类中定义一个**接口**。

> 注意，因为在三、配置 sqlSessionFactory 与 DataSource ，定义了自动载入 Mapper 类 。因此，需要加入了 `@Repository` 的注解，用于标注数据访问组件，即DAO 组件。否则不需要 `@Repository` 注解，但需要在 `*Mapper.xml` 中增加 配置。

<br/>

### 配置 Mapper.xml

在 `Mapper.xml` 中编写具体的数据库操作的 SQL。

其中，tag 有 `insert, select, update` 等

id 与 Mapper 接口方法名一一对应；

parameterType 为传入参数，可以是 POJO，也可以是 int、String 这种基本类型，SQL 中的参数用 `#{id}` 的形式表示；

resultType 或者 resultMap ，都是存储返回的结果集，其中 resultMap 比较强大，灵活；resultType 可以简单指定为 map 或者 POJO。

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd" >
<mapper namespace="com.test.dao.mapper.UserMapper">
    <!--配置一个resultMap 指定返回的类型 -->
    <resultMap id="userInfo" type="com.test.entity.User">
        <id column="id" property="id"/>
        <result column="name" property="name"/>
        <result column="age" property="age"/>
        <result column="gender" property="gender"/>
    </resultMap>

    <select id="queryUserInfos" resultMap="userInfo" parameterType="java.lang.Integer">
        SELECT * FROM t_user WHERE age = #{age} ORDER BY id DESC;
    </select>

    <insert id="insertUserInfo" parameterType="com.test.entity.User">
        INSERT INTO t_user(name, age, gender) VALUES (#{userName},#{age},#{gender})
        <selectKey resultType="int" keyProperty="id">
            SELECT LAST_INSERT_ID();
        </selectKey>
    </insert>
</mapper>
```

> 关于 `*Mapper.xml`文件的配置，详情参考[官方文档](http://www.mybatis.org/mybatis-3/zh/sqlmap-xml.html)

<br/>

### 通过服务调用

已经完成上述配置和接口等编写后，就可以在服务中调用了。

```Java
@Service(value = "userService")
public class UserServiceImpl implements UserService{
    @Autowired
    private UserMapper userMapper;

    @Override
    public List<User> getUser(Integer id) {
        List x =  userMapper.findUserById(id);
        return x;
    }

    @Override
    public Integer addUser(User user) {
        return userMapper.insertUser(user);
    }
}
```

在系统设计时，不会让服务直接就去调用如此底层的操作，往往会增加一个 model 层或者 controller 层。调用方法还是一致的，都是先注入 Mapper 接口，然后调用接口方法就可以了。

<br/><br/>

# 参考资料

1. MyBatis 与 Spring 集成，官网 <http://www.mybatis.org/spring/zh/getting-started.html>
2. MyBatis 官网，配置和使用介绍，<http://www.mybatis.org/mybatis-3/zh/configuration.html>
3. SSM框架——详细整合教程（Spring+SpringMVC+MyBatis），作者 shu_lin，<http://blog.csdn.net/zhshulin/article/details/37956105>