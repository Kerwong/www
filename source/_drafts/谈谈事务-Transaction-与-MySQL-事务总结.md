---
title: 谈谈事务 Transaction 与 MySQL 事务总结
comments: true
date: 2017-05-17 18:37:45
tags:
- MySQL
- Transaction
- ACID
---

在生活中，我们时常会遇到一系列连续不可中断的事情。
例如会计记账时，有借必有贷，借贷必相等；又如从 ATM 取钱时，银行卡金额必须扣除，并且要保持网银上看到的数额与 ATM 上的一致。
这些场景都是我们日常生活中经常遇到的。但仔细想想，这些事情，却是无法保持同时发生，而是存在先后的。
会计在记借后，然后记贷。
ATM 取钱，得先完成银行卡的扣款，然后才能吐钱。
正是由于事情发生有时间上的先后，那么就可能存在问题。如果会计在记完借后，中途被打断，忘记记贷了，账目不就不平了么？如果银行卡扣了款，但 ATM 没有收到扣款确认的反馈，而不吐钱怎么办？
 
为了解决这一类问题，便有了事务。

# 定义
事务（transaction） ：全有或全无的操作，是几个操作组合要么全部发生要么全部不发生的工作单元。

# 事务的 ACID 特性
在软件开发中，一般用一个术语描述事务：ACID 。ACID  表示 4 个特性。

- Atomic 原子性 ：确保事务中的所有操作全部发生或全部不发生。如果所有的活动都成功了，事务也就成功了。如果任意一个活动失败了，整个事务也失败回滚了。
- Consistent 一致性 ：一旦事务完成（不管成功还是失败），系统必须确保它所建模的业务处于一致的状态。现实的数据不应该被损坏。
- Isolated 隔离性 ：多个用户对相同的数据进行操作，每个用户的操作不会与其他用户纠缠在一起。避免发生同步读写相同数据的事情（注意的是，隔离性往往涉及到锁定数据库的行或表，会牺牲速度）
- Durable 持久性 ：事务完成后结果应该持久化，能从任何系统崩溃中恢复过来。一般就是将结果存储到数据库中。

当任意一个步骤失败时，所有步骤的操作结果都会被取消，从而保证了事务的原子性 。原子性 通过保证系统数据永远不会处于不一致或部分完成的状态来确保一致性 。隔离性同样确保了一致性 。最后，所有结果是持久化 的，提交到数据存储中。在发生系统崩溃或其他灾难性事情的时候，不用担心事务的结果丢失。

# 隔离级别
隔离级别（isolation level） ，隔离级别定义了一个事务可能受其他并发事务影响的程度。另一种考虑隔离级别的方式就是将其想象成事务对于事务性数据的自私程度。
 
- 脏读（Dirty reads） ：一个事务读取了另一个事务改写但尚未提交的数据。例如 A 事务更新了表中某一行数据，然后 B 事务读取了更新后的数据，如果此时 A 事务回滚了，那么 B 事务获取的数据就是无效的。
- 不可重复读（Nonrepeatable read） ：执行相同的查询两次或以上，但每次都得到不同数据时。这通常是因为另一个并发事务在两次查询期间更新了数据。
- 幻读（Phantom read） ：与不可重复读类似。它发生在一个事务 A 读取了几个数据，接着另一个并发事务 B 插入了一些数据时。在随后的查询中，第一个事务 A 就会发现多了一个原本不存在的记录。
 
| 隔离级别 | 含义 | 可能导致 |
| --- | --- | --- |
| ISOLATION_DEFAULT | 使用后端数据库默认的隔离级别 |  |
| ISOLATAION_READ_UNCOMMITTED 未提交读 | 允许读取尚未提交的数据变更 | 脏读、不可重复读、幻读 |
| ISOLATION_READ_COMMITTED 已提交读 | 允许读取并发事务已经提交的数据 | 不可重复读、幻读 |
| ISOLATION_REPEATABLE_READ 可重复读 | 对同一字段的多次读取结果是一致的，除非数据是被本事务自己所修改。 | 幻读 |
| ISOLATION_SERIALIZABLE 可串行化 | 完成服从 ACID 隔离级别，确保阻止脏读、不可重复读、幻读。这是最慢的事务隔离级别，因为它通常是通过完全锁定事务相关的数据库来实现的 | 无 |
 
隔离级别越低，事务请求的锁越少或保持锁的时间就越短。**InnoDB 存储引擎默认的支持隔离级别是REPEATABLE READ ；**在这种默认的事务隔离级别下已经能完全保证事务的隔离性要求，即达到 SQL  标准的SERIALIZABLE 级别隔离。

# MySQL 事务
MySQL  数据库中，并不是所有引擎都支持事务，常用的引擎 InnoDB  和 MyISAM  中仅有 InnoDB  支持事务。
 
MySQL 一般过程
```SQL
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

START TRANSACTION;
	SAVEPOINT step0;
	INSERT INTO `user` (name, age) VALUES ('aaa', 1),('bbb',2);	
	INSERT INTO `user` (name, age) VALUES ('ccc', 3),('ddd',4);
	
	SAVEPOINT step1;
	UPDATE `user` SET age=100 WHERE `name`='test';

	ROLLBACK TO step1;
```

## 事务语法
- SET TRANSACTION ；用来设置事务的隔离级别。InnoDB 存储引擎提供事务的隔离级别有 READ UNCOMMITTED 、READ COMMITTED 、REPEATABLE READ 和 SERIALIZABLE 。
- BEGIN 或START TRANSACTION ；显示地开启一个事务
- SAVEPOINT <identifier> ；SAVEPOINT 允许在事务中创建一个保存点，一个事务中可以有多个SAVEPOINT
- RELEASE SAVEPOINT <identifier> ；删除一个事务的保存点，当没有指定的保存点时，执行该语句会抛出一个异常
- COMMIT ；也可以使用COMMIT WORK ，不过二者是等价的。COMMIT 会提交事务，并使已对数据库进行的所有修改称为永久性的
- ROLLBACK ；有可以使用ROLLBACK WORK ，不过二者是等价的。回滚会结束用户的事务，并撤销正在进行的所有未提交的修改
- ROLLBACK TO <identifier> ；把事务回滚到标记点

## 一. 设置事务隔离级别
在编写事务时，第一步是要确定事务的隔离级别是什么。使用以下语法设置
```
SET [SESSION | GLOBAL] TRANSACTION ISOLATION LEVEL {READ UNCOMMITTED | READ COMMITTED | REPEATABLE READ | SERIALIZABLE}
```

- 默认为空（不带 SESSION 和 GLOBAL） ，为下一个（未开始）事务设置隔离级别。
- GLOBAL ，语句在全局对从那点开始创建的所有新连接（除了不存在的连接）设置默认事务级别。你需要SUPER权限来做这个。
- SESSION ，为将来在当前连接上执行的事务设置默认事务级别。 任何客户端都能自由改变会话隔离级别（甚至在事务的中间），或者为下一个事务设置隔离级别。

## 二. 开始事务
开始一个 MySQL 的事务有两种方法：
1. 用 BEGIN 或START TRANSACTION显示地开启一个事务。当遇到 COMMIT  或 ROLLBACK  时，结束该事务。
2. 用 SET  来改变 MySQL  的自动提交模式。MySQL 默认是自动提交的，但可以通过 `SET autocommit = 0` ， 禁止自动提交。但注意当你用 `SET autocommit = 0`  的时候，以后所有的SQL都将做为事务处理，直到你用 COMMIT  确认或 ROLLBACK  结束，当结束这个事务的同时也开启了个新的事务！按第一种方法只将当前的作为一个事务！

## 三. 设置以及释放 SAVEPOINT
保留点 SAVEPOINT  是为事务在执行过程中提供一个备份。当事务庞大时，保留点就显得格外有效。
一般的 ROLLBACK  是回滚整个事务，而使用 ROLLBACK TO SAVEPOINT  可以指定回滚到具体某一步。一来省去很多保留点之前的操作，二来更为灵活。
释放保留点 RELEASE SAVEPOINT <identifier>  是释放 SAVEPOINT ，保留点在事务处理完成后（无论是 COMMIT  或 ROLLBACK ）就会自动释放，无需自己释放。

## 四. 回滚 ROLLBACK
回滚就是恢复到事务执行之前，或者是恢复到 SAVEPOINT 所指向的某一步。
但是，并不是所有的 SQL 命令都是可以回滚的。有些 SQL 命令是包含隐式提交的，则无法回滚。具体有：
1. DDL语句，ALTER DATABASE 、ALTER EVENT 、ALTER PROCEDURE 、ALTER TABLE 、ALTER VIEW 、CREATE TABLE 、DROP TABLE 、RENAME TABLE 、TRUNCATE TABLE 等；
2. 修改 MySQL 架构的语句，CREATE USER 、DROP USER 、GRANT 、RENAME USER 、REVOKE 、SET PASSWORD ；
3. 管理语句，ANALYZE TABLE 、CACHE INDEX 、CHECK TABLE 、LOAD INDEX INTO CACHE 、OPTIMIZE TABLE 、REPAIR TABLE 等。

# 参考资料
- 《Spring 实战》（第3版）Craig Walls 著，耿渊 张卫滨 译
- MYSQL--事务处理，苏恒锋，http://www.cnblogs.com/in-loading/archive/2012/02/21/2361702.html
- 《MySQL必知必会学习笔记》：事务处理， HelloWorld_EE，http://blog.csdn.net/u010412719/article/details/51147292
- 说说MySQL中的事务，http://www.jellythink.com/archives/952