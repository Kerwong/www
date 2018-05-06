---
title: 深入学习 Java 并发编程（一）
comments: true
date: 2016-2-23 20:35:40
tags:
- Java
- Concurrency
---

并发是大型工程所无法避免的技术难题，一方面并发可以大幅的提升程序的效率，但另一方面，其对设计和技艺有着较高的要求，不当的设计会带来成堆的 bug，而且还有可能成为性能的瓶颈。

坦白的说，并发编程对我一直是一道坎。因此，在本博客中将采取一个系列对 Java 的并发编程做一次系统性的梳理，以此为鉴。

本系列主要参考 《Java 编程思想》 与 《Java 并发编程的艺术》两本书，将由基础至逐步深入的介绍并发。

<br/>

- 并发（Concurrency）：并发是指在一段时间内同时处理多项事务，通过时间片的轮转，分配 CPU 的资源，避免程序的阻塞。好比一位母亲在家同时照顾多个孩子，资源只有一份（母亲），但有多个事务（多个孩子），母亲只能依次照顾（切换上下文），避免孩子的哭闹（避免阻塞）。
- 并行（Parallel）：并行是针对多核而言，可以同时执行事务，接上面的例子，还是有多个孩子，但现在有父亲、母亲、保姆一同在照看孩子。并行虽然避免的上下文的切换和阻塞，但其代价是资源的浪费。因此在实际开发过程中，对并发的研究是重点。

<br/>

上面关于并发与并行做了比较。但实际中，并发存在着诸多问题。

- 如何合理分配时间？
- 如何上下文切换？
- 如何防止死锁？
- 如何检测性能，发现 bug？等等


让我在此系列文章中，一一介绍。

<br/>

<!--more-->

# 基本的线程机制

Java 的线程机制是抢占式的，调度机制会周期性中断线程，将上下文切换到另一个线程，从而为每个线程提供时间片。

Java 中最基础的定义线程操作是 `Runnable` 和 `Thread`。

- `Runnable` 是一个函数式接口，只定义了一个 `run()` 方法。
- 通常，`run()` 方法写成无限循环的形式，直至某个条件达成才退出。
- **`Runnable` 接口并不产生线程，必须显式地将任务附着在线程上。**

```java
public class MyRunnable implements Runnable {
    private static int count = 0;
    private final int tNo = count++;
    protected int countDown = 10;

    public MyRunnable(int countDown) {
        this.countDown = countDown;
    }

    @Override
    public void run() {
        while (countDown-- > 0) {
            System.out.printf("#%d, %s (%s)\n", tNo, Thread.currentThread(), countDown > 0 ? countDown : "Liftoff!");
            Thread.yield();		// 程序对线程调度器的建议，建议在此处进行任务切换，但不一定会被调度器采纳
        }
    }
}

////////////////////////////////////////////////
public class Test {
    public static void main(String[] args) {
        MyRunnable runnable = new MyRunnable(3);
        runnable.run();
        MyRunnable runnable1 = new MyRunnable(5);
        runnable1.run();
    }
}
```

输出，可以看到两个 runnable 均附着在 main 线程之上。无新的线程启用。

```
#0, Thread[main,5,main] (2)
#0, Thread[main,5,main] (1)
#0, Thread[main,5,main] (Liftoff!)
#1, Thread[main,5,main] (4)
#1, Thread[main,5,main] (3)
#1, Thread[main,5,main] (2)
#1, Thread[main,5,main] (1)
#1, Thread[main,5,main] (Liftoff!)
```

<br/>

将 `Runnable` 对象转变为 `Thread` 的传统方法，是采用 `Thread` 构造器。修改 `Test` 类如下

```java
public class Test {
    public static void main(String[] args) {
        Thread thread = new Thread(new MyRunnable(3));
        thread.start();
        Thread thread2 = new Thread(new MyRunnable(5));
        thread2.start();
    }
}
```

输出如下，可以看到线程名称变为了 `Thread-0` 和  `Thread-1`，并且可以看出输出是并发的。

```
#0, Thread[Thread-0,5,main] (2)
#1, Thread[Thread-1,5,main] (2)
#0, Thread[Thread-0,5,main] (1)
#1, Thread[Thread-1,5,main] (1)
#0, Thread[Thread-0,5,main] (Liftoff!)
#1, Thread[Thread-1,5,main] (Liftoff!)
```

<br/>

## 管理线程

上一节介绍了如何创建线程，但大量的线程难以管理。Java 通常的处理，是对线程进行池化。

在 Java 的 `java.util.concurrent` 包中提供了 `Executor` 来管理 Thread 对象。`ExecutorService` 是接口，定义了一系列管理线程池的方法，

```java
public class TestExecutor {
    public static void main(String[] args) {
        ExecutorService es = Executors.newFixedThreadPool(5);	// 定义一个固定大小的线程池
        for (int i = 0; i < 10; i++) {
            es.execute(new MyRunnable(10));	// 创建并执行线程
        }
        es.shutdown();	// 等待线程池内任务执行完毕后，关闭线程池
    }
}
```



| Pool                 | Description |
| -------------------- | ----------- |
| SingleThreadExecutor |             |
| CacheThreadPool      |             |
| FixedThreadPool      |             |
| ScheduledThreadPool  |             |
| WorkStealingPool     |             |

