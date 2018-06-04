---
title: 介绍一下-Redis-数据结构及其基本操作
comments: true
date: 2017-04-14 15:04:43
tags:
- Redis
---

# 前言
本篇文章介绍一下 Redis 的数据结构，以此作为 Redis 学习和使用的开篇。
对于现在的公司们而言，Redis 俨然已经成为了事实上的内存数据库、`NoSQL` 的标准工具，相比于传统的关系型数据库，Redis 将数据以 `键值对`存于内存中的处理方式，要比关系型数据库的硬盘读取，树形结构查找效率要高出不少，并且易用性也要好于关系数据库。

相比较于同类的 `memcached`， 二者处理类似，效率也属同一量级，但 Redis 支持更丰富的数据结构。

简单介绍下 Redis，下面来详细学习下 Redis 提供的数据结构。

# Redis 的数据结构

| 结构类型   | 结构存储的值           | 结构的读写能力                    |
| ------ | ---------------- | -------------------------- |
| STRING | 字符串、*整数*或*浮点数*   | 字符串处理；对整数与浮点数的自增/减操作       |
| LIST   | 列表，每个节点含一个字符串    | 支持 POP，PUSH 操作，支持随机访问等链表操作 |
| HASH   | 无序散列             | 一般散列操作                     |
| SET    | 无序集合，每个字符串仅可存在一个 | 增删改查的集合操作，支持集合的交、并、差集计算    |
| ZSET   | 有序集合，字符串元素以分值排序  | 增删改查等集合操作，支持 range 方法      |


下面来具体看看每种类型可用的处理方法：
## STRING 字符串

STRING 命令

| 命令   | 使用方式                        | 解释          |
| ---- | --------------------------- | ----------- |
| GET  | `get <redis-key> <value>` | 获取存储的给定键中的值 |
| SET  | `set <redis-key>`         | 设置存储在给定键中的值 |
| DEL  | `del <redis-key>`           | 删除存储在给定键中的值 |


```
127.0.0.1:6379> set hello world
OK
127.0.0.1:6379> get hello
"world"
127.0.0.1:6379> del hello
(integer) 1
127.0.0.1:6379> get hello
(nil)
```

## LIST 列表

LIST 命令

| 命令          | 使用方式                                     | 解释                                     |
| ----------- | ---------------------------------------- | -------------------------------------- |
| LPUSH/RPUSH | `lpush/rpush <redis-key> <value>`      | 将数据推入列表**左/右**边                        |
| LPOP/RPOP   | `lpop/rpop <redis-key>`                  | 将数据从**左/右**边弹出，并返回                     |
| LINDEX      | `lindex <redis-key> <index>`           | 获取指定下标的元素                              |
| LRANGE      | `lrange <redis-key> <start-index> <end-index>` | 获取列表给定范围内的数据，使用 0 作为起始，-1 作为结束可以取出所有元素 |


```
127.0.0.1:6379> lpush mylist 1
(integer) 1
127.0.0.1:6379> lpush mylist 2
(integer) 2
127.0.0.1:6379> rpush mylist 3
(integer) 3
127.0.0.1:6379> rpush mylist 4
(integer) 4
127.0.0.1:6379> lrange mylist 0 -1
1) "2"
2) "1"
3) "3"
4) "4"
127.0.0.1:6379> lpop mylist
"2"
127.0.0.1:6379> rpop mylist
"4"
127.0.0.1:6379> lrange mylist 0 -1
1) "1"
2) "3"
127.0.0.1:6379> lindex mylist 0
"1"
```

由以上操作可见，`rpush` 更接近于我们一般的列表在列尾增加数据的操作。


## HASH 散列

Redis 的散列，可以存储多个键值对之间的映射。Redis 中的散列结构，可以理解为类似 `Java` 中的 `Map<String, Map<String, Object>>` 结构。第一个 `String` 为 `Redis` 中的 `key`，第二个 `String` 为 `Hash` 中的 `key`。

| 命令      | 使用方式                                     | 解释                     |
| ------- | ---------------------------------------- | ---------------------- |
| HSET    | `hset <redis-key> <hash-key> <value>` | 在 Redis 中创建 HASH       |
| HGET    | `hget <redis-key> <hash-key>`          | 获取指定 key 的 value       |
| HGETALL | `hgetall <redis-key>`                    | 获取 Hash 中所有的 key-value |
| HDEL    | `hdel <redis-key>`                       | 删除 HASH 中指定 key        |


```
127.0.0.1:6379> hset redis-key hash-key1 1
(integer) 1
127.0.0.1:6379> hset redis-key hash-key2 2
(integer) 1
127.0.0.1:6379> hset redis-key hash-key3 3
(integer) 1
127.0.0.1:6379> hgetall redis-key
1) "hash-key1"
2) "1"
3) "hash-key2"
4) "2"
5) "hash-key3"
6) "3"
127.0.0.1:6379> hget redis-key hash-key1
"1"
127.0.0.1:6379> hdel redis-key hash-key1
(integer) 1
127.0.0.1:6379> hdel redis-key hash-key2
(integer) 1
127.0.0.1:6379> hgetall redis-key
1) "hash-key3"
2) "3"
```


## SET 无序集合

Redis 中的集合 Set，与 Java 中的 Set 类似，都是基于 HashMap 实现，Set 就是只有键，没有值的 HashMap。

| 命令        | 使用方法                              | 行为          |
| --------- | --------------------------------- | ----------- |
| SADD      | `sadd <redis-key> <value>`      | 在 set 中添加元素 |
| SMEMBERS  | `smembers <redis-key>`            | 返回集合所有元素    |
| SISMEMBER | `sismember <redis-key> <value>` | 检查元素是否存在于集合 |
| SREM      | `srem <redis-key>`                | 删除指定元素      |


```
127.0.0.1:6379> sadd set-key 1
(integer) 1
127.0.0.1:6379> sadd set-key 2
(integer) 1
127.0.0.1:6379> sadd set-key 3
(integer) 1
127.0.0.1:6379> sismember set-key 1
(integer) 1
127.0.0.1:6379> sismember set-key 4
(integer) 0
127.0.0.1:6379> smembers set-key
1) "1"
2) "2"
3) "3"
127.0.0.1:6379> srem set-key 1
(integer) 1
127.0.0.1:6379> srem set-key 2
(integer) 1
127.0.0.1:6379> smembers set-key
1) "3"
```


## ZSET 有序集合

`Zset`与`Set`的区别在于，`ZSet` 为每个集合中的元素定义了一个`分值`的概念，这使得`ZSet` 可以对集合中的元素按照分值进行排序。

> `分值`必须为**浮点数**


| 命令            | 使用方式                                     | 解释               |
| ------------- | ---------------------------------------- | ---------------- |
| ZADD          | `zadd <redis-key> <score> <value>`   | 将指定分值的元素加入集合     |
| ZRANGE        | `zrange <redis-key> <start-index> <end-index> [withscores]` | 根据集合内元素排序，获取多个元素 |
| ZRANGEBYSCORE | `zrangebyscore <redis-key> <start-score> <end-score> [withscores]` | 获取有序集合指定分值段内的元素  |
| ZREM          | `zrem <redis-key> <value>`             | 移出集合内元素          |


```
127.0.0.1:6379> zadd zset-key 777 member1
(integer) 1
127.0.0.1:6379> zadd zset-key 999 member2
(integer) 1
127.0.0.1:6379> zadd zset-key 333 member3
(integer) 1
127.0.0.1:6379> zrange zset-key 0 -1
1) "member3"
2) "member1"
3) "member2"
127.0.0.1:6379> zrange zset-key 0 -1 withscores
1) "member3"
2) "333"
3) "member1"
4) "777"
5) "member2"
6) "999"
127.0.0.1:6379> zrangebyscore zset-key 0 500
1) "member3"
127.0.0.1:6379> zrange zset-key 0 -2
1) "member3"
2) "member1"
127.0.0.1:6379> zrem zset-key member1
(integer) 1
127.0.0.1:6379> zrange zset-key 0 -1
1) "member3"
2) "member2"
```


