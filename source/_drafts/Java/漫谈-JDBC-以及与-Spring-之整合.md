---
title: 漫谈 JDBC 以及与 Spring 之整合
date: 2016-10-14 22:54:38
tags: 
- JDBC
- Spring
---

# 介绍 JDBC
JDBC  是 Java 数据库连接（Java Database Connectivity）的简称，是Java语言中用来规范客户端程序如何来访问数据库的应用程序接口，用来连接 Java 与数据库，提供了诸如查询和更新数据库中数据的方法。

## JDBC 架构
JDBC  的 API  支持两层和三层处理模式进行数据库访问，但一般的 JDBC  架构由两层处理模式组成：

* JDBC API : 提供了应用程序对 JDBC  管理器的连接。
* JDBC Driver API : 提供了 JDBC  管理器对驱动程序连接。

JDBC API  使用驱动程序管理器和数据库特定的驱动程序来提供异构（heterogeneous）数据库的透明连接。

JDBC  驱动程序管理器可确保正确的驱动程序来访问每个数据源。该驱动程序管理器能够支持连接到多个异构数据库的多个并发的驱动程序。

以下是结构图，其中显示了驱动程序管理器相对于在 JDBC  驱动程序和 Java  应用程序所处的位置。

![](http://nutslog.qiniudn.com/17-5-17/52617002-file_1495004437453_1171b.jpg "JDBC 组件")

## API 与类概述
> JDBC API 主要位于JDK 中的java.sql 包中（之后扩展的内容位于javax.sql 包中），主要包括（斜体代表接口，需驱动程序提供者来具体实现）：

> `DriverManager` ：负责加载各种不同驱动程序（Driver ），并根据不同的请求，向调用者返回相应的数据库连接（Connection ）。
> `Driver` ：驱动程序，会将自身加载到DriverManager 中去，并处理相应的请求并返回相应的数据库连接（Connection ）。
> `Connection` ：数据库连接，负责进行与数据库间的通讯，SQL 执行以及事务处理都是在某个特定Connection 环境中进行的。可以产生用以执行SQL 的Statement 。
> **`Statement` ：用以执行SQL 查询和更新（针对静态SQL 语句和单次执行）。
> `PreparedStatement` ：用以执行包含动态参数的SQL 查询和更新（在服务器端编译，允许重复执行以提高效率）。
> `CallableStatement` ：用以调用数据库中的存储过程。**
> `SQLException` ：代表在数据库连接的创建和关闭和SQL语句的执行过程中发生了例外情况（即错误）。
> 摘自 wikipedia，Java数据库连接，https://zh.wikipedia.org/wiki/Java%E6%95%B0%E6%8D%AE%E5%BA%93%E8%BF%9E%E6%8E%A5

除了以上 API ，JDBC  还提供了以下类：

`ResultSet`  : 在你使用语句对象执行 SQL  查询后，这些对象保存从数据获得的数据。它作为一个迭代器，让您可以通过它的数据来移动。

## JDBC 使用基本思路
1. 制作到数据库的连接。
2. 创建 SQL 或 MySQL 语句。
3. 执行 SQL 或 MySQL 查询数据库。
4. 查看和修改所产生的记录。

# J2SE 通过 JDBC 连接数据库
## 前期准备
1. 安装完成 Java
2. 部署好数据库，以下采用的是 MySQL  数据库
3. 下载相关驱动，MySQL 的 JDBC 驱动为使用的是 mysql-connector-java-5.1.32-bin.jar ，[下载地址](https://dev.mysql.com/downloads/connector/j/3.1.html)

## 创建 JDBC 应用程序
1. 导入数据包 . 需要包括含有需要进行数据库编程的JDBC类 的包。大多数情况下，使用 import java.sql.*  就可以了.
2. 注册JDBC驱动程序 . 需要初始化驱动程序，可以与数据库打开一个通信通道。
3. 打开连接. 需要使用DriverManager.getConnection()  方法创建一个Connection 对象，它代表与数据库的物理连接。
4. 执行查询 . 需要使用类型声明的对象建立并提交一个SQL 语句到数据库。
5. 从结果集中提取数据 . 要求使用适当的关于ResultSet.getXXX() 方法来检索结果集的数据。
6. 清理环境. 需要明确地关闭所有的数据库资源相对依靠JVM 的垃圾收集。

```java
/** STEP 1. Import required packages 导入数据包 */
import java.sql.*;

public class JDBCExample {
    /** JDBC driver name and database URL
     *  定义 JDBC 驱动以及数据库地址，此处数据库为本地的 test */
    static final String JDBC_DRIVER = "com.mysql.jdbc.Driver";
    static final String DB_URL = "jdbc:mysql://localhost/test";

    /**  Database credentials
     *   数据库的账号、密码
     */
    static final String USER = "root";
    static final String PASS = "";

    public static void main(String[] args) {
        Connection conn = null;
        Statement stmt = null;
        try{
            /** STEP 2: Register JDBC driver
             * 加载 JDBC 驱动程序 Driver 至 DriverManager */
            Class.forName(JDBC_DRIVER);

            /** STEP 3: Open a connection
             *  通过 DB_URL, 数据库账号和密码来获取相应的数据库连接 */
            System.out.println("Connecting to database...");
            conn = DriverManager.getConnection(DB_URL,USER,PASS);

            /** STEP 4: Execute a query
             *  获取 connection 之后，可以创建 Statement 用来执行 SQL 语句
             *  其中 结果存储在 ResultSet 结果集 */
            System.out.println("Creating statement...");
            stmt = conn.createStatement();
            String sql;
            sql = "SELECT * FROM t_user";
            ResultSet rs = stmt.executeQuery(sql);

            /** STEP 5: Extract data from result set
             *  通过遍历结果集顺序访问数据
             *  具体是 getInt 还是 getString，请参考附录一：SQL 到 Java 的数据类型的映射*/
            while(rs.next()){
                //Retrieve by column name
                int id  = rs.getInt("id");
                String name = rs.getString("name");
                int age = rs.getInt("age");
                int gender = rs.getInt("gender");

                //Display values
                System.out.println("ID: " + id + ", Name: " + name
                        + ", Age: " + age + ", Gender: " + gender);
            }
            /** STEP 6: Clean-up environment
             * 清理环境，需要关闭结果集、Statement 以及数据库连接
             * 注意！关闭的顺序！*/
            rs.close();
            stmt.close();
            conn.close();
        }catch(SQLException se){
            /** Handle errors for JDBC
             * 如果数据库操作失败，JDBC将抛出一个SQLException。
             * 一般来说，此类异常很少能够恢复，唯一能做的就是尽可能详细的打印异常日记。
             * 推荐的做法是将SQLException翻译成应用程序领域相关的异常（非强制处理异
             * 常）并最终回滚数据库和通知用户。*/
            se.printStackTrace();
        }catch(Exception e){
            //Handle errors for Class.forName
            e.printStackTrace();
        }finally{
            //finally block used to close resources
            try{
                if(stmt!=null)
                    stmt.close();
            }catch(SQLException se2){
            }// nothing we can do
            try{
                if(conn!=null)
                    conn.close();
            }catch(SQLException se){
                se.printStackTrace();
            }
        }
        System.out.println("Goodbye!");
    }
}
```

以上一例为模板，以下例子仅填充
```java
Connection conn = null;
Statement stmt = null;
PreparedStatement pstmt = null;

try {
    Class.forName(JDBC_DRIVER);
    conn = DriverManager.getConnection(DB_URL, USER, PASS);

    /* 在此填充代码 */

} catch (ClassNotFoundException e) {
    e.printStackTrace();
} catch (SQLException e) {
    e.printStackTrace();
} finally {
    try {
        if (stmt != null)
            stmt.close();
    } catch (SQLException se2) {
        try {
            if (conn != null)
                conn.close();
        } catch (SQLException se) {
            se.printStackTrace();
        }
    }
}
```

### Example 1：executeQuery()，仅单行数据
返回一个 ResultSet 对象。当希望得到一个结果集时使用该方法，如使用 SELECT 语句。
```java
//////// Example 1: statement, executeQuery
stmt = conn.createStatement();
String sql1 = "SELECT COUNT(DISTINCT `name`) AS 'cnt' FROM `user`";
ResultSet rs = stmt.executeQuery(sql1);

while (rs.next()) {
    int cnt1 = rs.getInt(1); // 此处的 column，第一列下标为 1，而非 0
    int cnt2 = rs.getInt("cnt");
    System.out.println("count: " + cnt1 + ", " + cnt2);
}
rs.close();
```

### Example 2：executeUpdate()
返回执行 SQL 语句影响的行的数目。使用该方法来执行 SQL 语句，得到一些受影响的行的数目，例如，INSERT，UPDATE 或 DELETE 语句
```java
//////// Example 2: statement, executeUpdate
String sql2 = "INSERT INTO `user`(name, age) VALUES ('noname', 30)";
int ret2 = stmt.executeUpdate(sql2);
```

### Example 3：execute()
如果 ResultSet 对象可以被检索，则返回的布尔值为 true ，否则返回 false 。当需要使用真正的动态 SQL 时，可以使用这个方法来执行 SQL DDL 语句。
```java
//////// Example 3: statement, execute
String sql3 = "CREATE TABLE tmp(id int,name VARCHAR(255))";
boolean ret3 = stmt.execute(sql3);
```

### Example 4：PrepareStatement
使用问号作为参数的标示。进行参数设置与大部分Java API中下标的使用方法不同，字段的下标从1开始，1代表第一个问号
```java
/////// Example 4: preparedStatement
String sql4 = "SELECT * FROM `user` WHERE name=? AND age=?";
pstmt = conn.prepareStatement(sql4);
pstmt.setString(1, "test");
pstmt.setInt(2, 10);
ResultSet rs4 = pstmt.executeQuery();
while (rs4.next()) {
    String name = rs4.getString("name");
    int age = rs4.getInt("age");
    System.out.println("Name: " + name + ", " + "Age: " + age);
}
rs4.close();
```

### Example 5：JDBC 下的事务
```java
///////// Example 5: 事务与回滚 transaction and rollback
boolean autoCommitDefault = false;
Savepoint savepoint1 = null;
Savepoint savepoint2 = null;
try {
    Class.forName(JDBC_DRIVER);
    conn = DriverManager.getConnection(DB_URL, USER, PASS);

    autoCommitDefault = conn.getAutoCommit();
    // 关闭自动提交，数据库默认时，是自动提交的
    conn.setAutoCommit(false);
    stmt = conn.createStatement();

    String sql5 = "SELECT * FROM `user` WHERE age=10";
    String sql6 = "INSERT INTO `user`(name, age) VALUES ('name1',1),('name2', 2)";
    String sql7 = "UPDATE `user` SET `name`='newname' WHERE age=10";
    stmt.executeQuery(sql5);
    savepoint1 = conn.setSavepoint("Savepoint1");
    stmt.executeUpdate(sql6);
    savepoint2 = conn.setSavepoint("Savepoint2");
    stmt.executeUpdate(sql7);
    conn.commit();

} catch (Throwable e) {
    try {
        // 回滚, 至 savepoint2. savepoint 非必须
        conn.rollback(savepoint2);
    } catch (Throwable ignore) {}
    throw e;
} finally {
    try {
        // 将 commit 设回默认值
        conn.setAutoCommit(autoCommitDefault);
    } catch (Throwable ignore) {}

    try {
        if (stmt != null)
            stmt.close();
    } catch (SQLException se2) {
        try {
            if (conn != null)
                conn.close();
        } catch (SQLException se) {
            se.printStackTrace();
        }
    }
}
```

### Example 6：JDBC 下的存储过程
** TODO **
```java
/*
 * 有IN 类型的参数输入 和Out类型的参数输出    
 */
public static void inOutTest(){
    Connection connection = null;
    Statement statement = null;
    ResultSet resultSet = null;
    try {
        Class.forName("oracle.jdbc.driver.OracleDriver").newInstance();
        
        Driver driver = DriverManager.getDriver(URL);
        Properties props = new Properties();
        props.put("user", USER_NAME);
        props.put("password", PASSWORD);
        
        connection = driver.connect(URL, props);
        
        //获得Statement对象,这里使用了事务机制，如果创建存储过程语句失败或者是执行compile失败，回退
        connection.setAutoCommit(false);
        statement = connection.createStatement();
        String procedureString = "CREATE OR REPLACE PROCEDURE get_job_min_salary_proc("
                                    +"input_job_id IN VARCHAR2,"
                                    +"output_salary OUT number) AS "
                                    +"BEGIN "
                                    +"SELECT min_salary INTO output_salary FROM jobs WHERE job_id = input_job_id; "
                                    +"END   get_job_min_salary_proc;";
        //1 创建存储过程,JDBC 数据库会编译存储过程
        statement.execute(procedureString);
        //成功则提交
        connection.commit();
        //2.创建callableStatement
        CallableStatement callableStatement = connection.prepareCall("CALL get_job_min_salary_proc(?,?)");
        //3，设置in参数
        callableStatement.setString(1, "AD_PRES");
        //4.注册输出参数
        callableStatement.registerOutParameter(2, Types.NUMERIC);
        //5.执行语句
        callableStatement.execute();
        
        BigDecimal salary = callableStatement.getBigDecimal(2);
        System.out.println(salary);
    } catch (ClassNotFoundException e) {
        System.out.println("加载Oracle类失败！");
        e.printStackTrace();
    } catch (SQLException e) {
        try {
            connection.rollback();
        } catch (SQLException e1) {
            e1.printStackTrace();
        }
        e.printStackTrace();
    } catch (InstantiationException e) {
        e.printStackTrace();
    } catch (IllegalAccessException e) {
        e.printStackTrace();
    }finally{
            //使用完成后管理链接，释放资源，释放顺序应该是： ResultSet ->Statement ->Connection
            try {
                statement.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
            
            try {
                connection.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
    }
}
```

# 附录一
## SQL 到 Java 的数据类型的映射
| SQL类型         | Java类型               |
| ------------- | -------------------- |
| CHAR          | java.lang.String     |
| VARCHAR       | java.lang.String     |
| LONGVARCHAR   | java.lang.String     |
| NUMERIC       | java.math.BigDecimal |
| DECIMAL       | java.math.BigDecimal |
| BIT           | boolean              |
| TINYINT       | byte                 |
| SMALLINT      | short                |
| INTEGER       | int                  |
| BIGINT        | long                 |
| REAL          | float                |
| FLOAT         | double               |
| DOUBLE        | double               |
| BINARY        | byte[]               |
| VARBINARY     | byte[]               |
| LONGVARBINARY | byte[]               |
| DATE          | java.sql.Date        |
| TIME          | java.sql.Time        |
| TIMESTAMP     | java.sql.Timestamp   |
| BLOB          | java.sql.Blob        |
| CLOB          | java.sql.Clob        |
| Array         | java.sql.Array       |
| REF           | java.sql.Ref         |
| Struct        | java.sql.Struct      |

# 参考资料
- http://www.yiibai.com/jdbc/
- http://wiki.jikexueyuan.com/project/jdbc/
- http://www.cnblogs.com/hongten/archive/2011/03/29/1998311.html
- https://zh.wikipedia.org/wiki/Java%E6%95%B0%E6%8D%AE%E5%BA%93%E8%BF%9E%E6%8E%A5