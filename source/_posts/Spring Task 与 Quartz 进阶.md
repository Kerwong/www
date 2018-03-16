---
title: 'Spring Scheduler 与 Quartz 进阶'
comments: true
date: 2016-12-23 15:35:47
tags:
- Spring
- Quartz
---

在工程中时常会遇到一些需求，例如定时刷新一下配置、隔一段时间检查下网络状态并发送邮件等诸如此类的定时任务。

定时任务本质就是一个异步的线程，线程可以查询或修改并执行一系列的操作。由于本质是线程，在 Java 中可以自行编写一个线程池对定时任务进行控制，但这样效率太低了，且功能有限，属于重复造轮子。

事实上，当前实现定时任务已经有了比较好的解决方案，大致有以下几种：

1. Spring Scheduler 框架
2. Quartz 框架，功能强大，配置灵活（自然更繁琐 =。=）

本文将总结 Spring 定时任务。Let's Begin

<!--more-->

# Spring Scheduler

Spring 于 3.0 版本引入了 `TaskScheduler`，相比较于 Spring 2.0 时的  `TaskExecutor`，简化了对线程的管理，线程均由框架管理，不需要指定调度器 `scheduler` 实现，可以自定义调度的间隔和时间，相对的对线程池等的功能较简单。

<br/>

<u>**`TaskExecutor` 与 `TaskScheduler` 的区别**</u>

<u>Scheduler 只是任务的简单调度，可以指定任务的执行时间，但对任务队列和线程池的管控较弱，定时调度的主要目的还是控制执行时间。</u>

<u> Executor 则提供了更细化线程池配置，如等待队列容量、存活时间控制，也支持异步执行任务。TaskExecutor 可以理解为是 Spring 框架下的线程池管理，是从 JDK 5 中对 Executor 接口的抽离，主要职责并不在于几点几分几秒去执行什么任务。</u>

<br/>

定时调度实现依赖于 `spring-context` 包。因此 Maven 中需加入以下依赖配置。

```xml
<dependency>
    <groupId>org.springframework</groupId>
    <artifactId>spring-context</artifactId>
    <version>${spring.version}</version>
</dependency>
```

与定时任务相关的代码，位于包 `org.springframework.scheduling` 下。源码并不复杂，可以花点时间读一读。

<br />

## Spring TaskScheduler实践

作为 Spring 下的框架，一些 Spring 的基本配置就此略过。

###  XML 配置

1. **定义 Task 类**

```java
@Lazy
@Service
public class DemoTask {
    public void job1() {
        System.out.println("Task job1: " + System.currentTimeMillis());
    }

    public void job2() {
        System.out.println("Task job2: " + System.currentTimeMillis());
    }
}
```

其中 `@Lazy` 注解表明不执行 Bean 的初始化。



2. **XML 配置**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:task="http://www.springframework.org/schema/task"
       xsi:schemaLocation="http://www.springframework.org/schema/task http://www.springframework.org/schema/task/spring-task.xsd
		http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd">

    <task:scheduler id="demoTaskBean" pool-size="2"/>
    <task:scheduled-tasks scheduler="demoTaskBean">
        <task:scheduled ref="demoTask" method="job1" fixed-rate="100" initial-delay="200" cron="" fixed-delay="300"/>
        <task:scheduled ref="demoTask" method="job2" cron="*/5 * * * * ?"/>
    </task:scheduled-tasks>
</beans>
```

XML 的配置，定义一个 scheduler，然后定义具体任务 scheduled-task。

1. `task:scheduler` 定义一个 `ThreadPoolTaskScheduler`, 提供唯一参数指定了池大小。
   - `pool-size`: 任务池大小。池的大小控制着 `task:scheduled` 的执行，例如以上例子，若 pool-size = 1，则两个 task 只能依次运行，无法并行执行。


2. `task:scheduled-tasks` ：指定所采用的任务池

   - `scheduler`: 定义的任务池 Bean 的 ID，若不指定，则会被包装为一个单线程 `Executor`
   - `task:scheduled` : 指定具体任务，至少有一个，其参数如下表

| 参数名           | 说明                                       |
| ------------- | ---------------------------------------- |
| initial-delay | 任务初始延迟，单位 milliseconds                   |
| fixed-delay   | 任务固定间隔时间，时间自前一次**完成**后计算，单位 milliseconds |
| fixed-rate    | 任务固定间隔时间，时间自前一次**开始**后计算，单位 milliseconds |
| **cron**      | **cron 表达式**                             |
| trigger       | 实现  `Trigger` 接口的 Bean 的引用               |
| ref           | 具体 Task 的方法所在类                           |
| method        | 具体 Task 的方法名                             |



> cron 表达式请参考附录



### 注解配置

1. 定义 Task 类

```java
@Service
public class DemoTask {
    @Scheduled(cron = "5 * * * * ?")
    public void job1() {
        System.out.println("Task job1: " + System.currentTimeMillis());
    }

    @Scheduled(initialDelay = 100, fixedDelay = 1000)
    public void job2() {
        System.out.println("Task job2: " + System.currentTimeMillis());
    }
}
```

2. 添加注解驱动配置

```xml
<task:annotation-driven />
```



>  更多细节，建议查看 xsd 文件和 Spring 源码

<br/>

## Scheduling 框架源码分析

Scheduleing 部分的源码是比较清晰和简单的。

Scheduleing 中最重要的类是 `ThreadPoolTaskScheduler` ，这是使用 schedule 时的默认的线程池，其类图如下：

![](http://nutslog.qiniudn.com/18-2-27/41314782.jpg)

在  `ThreadPoolTaskScheduler` 中定义了一些内部变量

```java
// ScheduledThreadPoolExecutor.setRemoveOnCancelPolicy(boolean) only available on JDK 7+
private static final boolean setRemoveOnCancelPolicyAvailable =
	ClassUtils.hasMethod(ScheduledThreadPoolExecutor.class, "setRemoveOnCancelPolicy", boolean.class);

private volatile int poolSize = 1;
private volatile boolean removeOnCancelPolicy = false;
private volatile ScheduledExecutorService scheduledExecutor;
private volatile ErrorHandler errorHandler;
```

需要关注的是 `ScheduledExecutorService scheduledExecutor`，这是一个继承了 `ExecutorService` 接口的一个接口，是在 `ExecutorService` 基础上新增了定时调度的几个方法，`scheduledExecutor` 的具体实现是 `java.util.concurrent.ScheduledThreadPoolExecutor`，具体可以查看 JDK 源码。

除了定义 Executor 类，还实现了`AsyncListenableTaskExecutor`,`SchedulingTaskExecutor`, `TaskScheduler` 三个接口的相关方法，此处不再赘述。

<br/>

## 存在的问题

1. 注意线程池和任务数的关系

   在实践中，若出现线程池数小于任务数时，任务将进入队列，按照配置中的顺序执行。此时，若对任务的执行时间有严格要求的话，将无法被满足。例如定义了两个任务均需要在整分钟时执行，任务执行分别需要花费 20s 和 30s。那么在一个线程池下，将先执行第一个 20s 的任务，完成后再执行第二个 30s 的任务。

2. 注意 `fixedDelay` 和 `fixedRate` 之间的区别。前者是任务完成后计时，后者是从任务开始时计时。如果每分钟执行一次任务，但任务执行时间大于一分钟的话，`fixedRate` 将会出现任务在队列中的堆积的问题

3. 多实例执行的问题。由于 Spring Task 是集成与 Spring 框架之内的，若部署采取了多实例部署方案，并设计了定时调度单一资源的任务，如定时刷新 Redis 数据，定时更新 MySQL 数据等等，将会出现问题。解决此问题，一是放弃实例中使用 Spring Task，将定时调度单独部署与一台机器，但这种方案的缺点是增加了维护的成本而且造成了单点故障的问题；二是采用锁机制，一般而言可以将锁至于缓存数据库中，每次定时任务执行时，先请求锁资源，若失败，则不执行，只有请求到锁资源的定时任务才执行。

<br/>

# 进阶学学 Quartz

// TBD

# 总结

Scheduling 是专注于定时任务调度的框架，但 Spring Task 不仅仅是这一块。事实上，Task 部分更多阐述了 TaskExecutor 的内容，这也是 Scheduling 所依赖的。

并发、线程池、异步等等，均在 TaskExecutor 中做了详细的说明，这一块需要在之后的学习中做进一步的总结。

<br/>

# 附录

## Cron 表达式 (摘自 Quartz)

| Field Name   | Mandatory | Allowed Values   | Allowed Special Characters |
| ------------ | --------- | ---------------- | -------------------------- |
| Seconds      | YES       | 0-59             | , - * /                    |
| Minutes      | YES       | 0-59             | , - * /                    |
| Hours        | YES       | 0-23             | , - * /                    |
| Day of month | YES       | 1-31             | , - * ? / L W              |
| Month        | YES       | 1-12 or JAN-DEC  | , - * /                    |
| Day of week  | YES       | 1-7 or SUN-SAT   | , - * ? / L #              |
| Year         | NO        | empty, 1970-2099 | , - * /                    |

> 因此 cron 表达式可以是 6-7 位。



### 特殊字符

- `*` (*“all values”*) - used to select all values within a field. For example, `*` in the minute field means *“every minute”*.
- `?` (*“no specific value”*) - useful when you need to specify something in one of the two fields in which the character is allowed, but not the other. For example, if I want my trigger to fire on a particular day of the month (say, the 10th), but don’t care what day of the week that happens to be, I would put `10` in the day-of-month field, and `?` in the day-of-week field. See the examples below for clarification.
- `-` - used to specify ranges. For example, `10-12` in the hour field means *“the hours 10, 11 and 12”*.
- `,` - used to specify additional values. For example, `MON,WED,FRI` in the day-of-week field means *“the days Monday, Wednesday, and Friday”*.
- `/` - used to specify increments. For example, `0/15` in the seconds field means *“the seconds 0, 15, 30, and 45”*. And `5/15` in the seconds field means *“the seconds 5, 20, 35, and 50”*. You can also specify `/` after the `*` character - in this case `*` is equivalent to having `0` before the `/`. `1/3` in the day-of-month field means *“fire every 3 days starting on the first day of the month”*.
- `L` (*“last”*) - has different meaning in each of the two fields in which it is allowed. For example, the value `L` in the day-of-month field means *“the last day of the month”* - day 31 for January, day 28 for February on non-leap years. If used in the day-of-week field by itself, it simply means `7` or `SAT`. But if used in the day-of-week field after another value, it means *“the last xxx day of the month”* - for example `6L` means *“the last friday of the month”*. You can also specify an offset from the last day of the month, such as `L-3` which would mean the third-to-last day of the calendar month. *When using the `L` option, it is important not to specify lists, or ranges of values, as you’ll get confusing/unexpected results.*
- `W` (*“weekday”*) - used to specify the weekday (Monday-Friday) nearest the given day. As an example, if you were to specify `15W` as the value for the day-of-month field, the meaning is: *“the nearest weekday to the 15th of the month”*. So if the 15th is a Saturday, the trigger will fire on Friday the 14th. If the 15th is a Sunday, the trigger will fire on Monday the 16th. If the 15th is a Tuesday, then it will fire on Tuesday the 15th. However if you specify `1W` as the value for day-of-month, and the 1st is a Saturday, the trigger will fire on Monday the 3rd, as it will not ‘jump’ over the boundary of a month’s days. The `W` character can only be specified when the day-of-month is a single day, not a range or list of days.

> The `L` and `W` characters can also be combined in the day-of-month field to yield `LW`, which translates to *"last weekday of the month"*.

- `#` - used to specify “the nth” XXX day of the month. For example, the value of `6#3` in the day-of-week field means *“the third Friday of the month”* (day 6 = Friday and `#3` = the 3rd one in the month). Other examples: `2#1` = the first Monday of the month and `4#5` = the fifth Wednesday of the month. Note that if you specify `#5` and there is not 5 of the given day-of-week in the month, then no firing will occur that month.

> The legal characters and the names of months and days of the week are not case sensitive. `MON` is the same as `mon`.



### 举例

以下是摘自 Quartz 的完整例子

| **Expression**             | **Meaning**                              |
| -------------------------- | ---------------------------------------- |
| `0 0 12 * * ?`             | Fire at 12pm (noon) every day            |
| `0 15 10 ? * *`            | Fire at 10:15am every day                |
| `0 15 10 * * ?`            | Fire at 10:15am every day                |
| `0 15 10 * * ? *`          | Fire at 10:15am every day                |
| `0 15 10 * * ? 2005`       | Fire at 10:15am every day during the year 2005 |
| `0 * 14 * * ?`             | Fire every minute starting at 2pm and ending at 2:59pm, every day |
| `0 0/5 14 * * ?`           | Fire every 5 minutes starting at 2pm and ending at 2:55pm, every day |
| `0 0/5 14,18 * * ?`        | Fire every 5 minutes starting at 2pm and ending at 2:55pm, AND fire every 5 minutes starting at 6pm and ending at 6:55pm, every day |
| `0 0-5 14 * * ?`           | Fire every minute starting at 2pm and ending at 2:05pm, every day |
| `0 10,44 14 ? 3 WED`       | Fire at 2:10pm and at 2:44pm every Wednesday in the month of March. |
| `0 15 10 ? * MON-FRI`      | Fire at 10:15am every Monday, Tuesday, Wednesday, Thursday and Friday |
| `0 15 10 15 * ?`           | Fire at 10:15am on the 15th day of every month |
| `0 15 10 L * ?`            | Fire at 10:15am on the last day of every month |
| `0 15 10 L-2 * ?`          | Fire at 10:15am on the 2nd-to-last last day of every month |
| `0 15 10 ? * 6L`           | Fire at 10:15am on the last Friday of every month |
| `0 15 10 ? * 6L`           | Fire at 10:15am on the last Friday of every month |
| `0 15 10 ? * 6L 2002-2005` | Fire at 10:15am on every last friday of every month during the years 2002, 2003, 2004 and 2005 |
| `0 15 10 ? * 6#3`          | Fire at 10:15am on the third Friday of every month |
| `0 0 12 1/5 * ?`           | Fire at 12pm (noon) every 5 days every month, starting on the first day of the month. |
| `0 11 11 11 11 ?`          | Fire every November 11th at 11:11am.     |

> Pay attention to the effects of '?' and '*' in the day-of-week and day-of-month fields!

<br/>

# 参考资料

[1] Spring docs, Task Execution and Scheduling.  https://docs.spring.io/autorepo/docs/spring-framework/4.2.x/spring-framework-reference/html/scheduling.html

[2] Spring ThreadPoolTaskScheduler vs ThreadPoolTaskExecutor
 https://stackoverflow.com/questions/33453722/spring-threadpooltaskscheduler-vs-threadpooltaskexecutor
[3] Cron Trigger Tutorial， http://www.quartz-scheduler.org/documentation/quartz-2.2.x/tutorials/crontrigger