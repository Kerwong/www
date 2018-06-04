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

## 线程基本操作

### 定义任务

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

### 创建线程

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

### 定义有返回的任务 Callable

采用 `Runnable` 创建任务时，执行是无返回结果的。若需要返回结果，则可采用 `Callable` 接口。该接口也是函数式接口，仅有一个方法 `call()`。

```java
public class MyCallable implements Callable {
    private final int id;
    public MyCallable(int id) {
        this.id = id;
    }

    @Override
    public Object call() {
        for (int i = 0; i < 10; i++) {
            System.out.printf("#id: %d, thread: %s, count: %s\n", id, Thread.currentThread(), i);
            Thread.yield();
        }
        return id;
    }
}

///////////////////////////////////////
public class TestCallable {
    private final static int COUNT = 20;
    private static List<Future<Object>> futures = new ArrayList<>(COUNT);

    public static void main(String[] args) {
        ExecutorService es = Executors.newFixedThreadPool(10);
        for (int i = 0; i < COUNT; i++) {
            futures.add(i, es.submit(new MyCallable(i)));	// 将结果保存在 List 中。
        }
        es.shutdown();
        Thread t = new Thread(new ListenFutures());		// 新起一个线程，用于监控返回结果，若返回则打印
        t.start();
    }
    
    private static class ListenFutures implements Runnable {
        private Set<Integer> set = new HashSet<>();
        @Override
        public void run() {
            while (set.size() != COUNT) {
                for (int i = 0; i < COUNT; i++) {
                    if (!set.contains(i) && futures.get(i).isDone()) {
                        try {
                            System.out.printf("res: %s\n", futures.get(i).get());
                            set.add(i);
                        } catch (InterruptedException | ExecutionException e) {
                            e.printStackTrace();
                        }
                    }
                }
            }
        }
    }
}
```

以上需要注意几点：

1. `Callable` 任务需通过 `submit` 方法，而非 `execute` 方法
2. `Future` 调用 `get()` 方法时，会阻塞。因此不能在 `submit` 之后立刻 `get`。

<br/>

### 线程休眠 sleep()

线程休眠是暂时中止线程任务执行。

- 早期版本采用 `Thread.sleep(long millis);` 中止线程。
- Java 1.5 后，提供了更简单的实现 `TimeUnit.SECONDS.sleep(timeout);` 。`TimeUnit` 底层也是通过 `Thread.sleep` 实现的，因此这两者本质并无区别，只是 `TimeUnit` 可以更方便的转换时间。

<br/>

### 线程优先级 setPriority()

可以为线程定义一定的优先级，优先级别高的线程将被优先调度。

```Java
public class MyPriority implements Runnable {
    private final int priority;
    private final int id;

    public MyPriority(int priority, int id) {
        this.priority = priority;
        this.id = id;
    }

    @Override
    public void run() {
        Thread.currentThread().setPriority(priority);

        while (true) {
            System.out.printf("#id: %d, priority: %d\n", id, priority);
            try {
                TimeUnit.SECONDS.sleep(1);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
    }
}
```

注意两点：

1. `setPriority` 必须位于在 `run` 方法的最开始。若在构造函数中，则无效。因为此时执行器还未执行。
2. JDK 提供了 3 档优先级，`MIN, NORM, MAX` 分别对应 1，5，10。考虑到与系统兼容性的问题，建议采用这三档。

<br/>

### 线程让步 yield()

如上文所属，Java 采用 `Thread.yield()` 告诉调度器，当前处于切换任务的合适时机。但这仅仅是建议，是否采纳取决于调度器。

<br/>

### 后台线程 setDaemon()

Java 可以定义线程为后台线程，通过 `Thread.currentThread().setDaemon(true);` 开启。

**必须在 `Thread.start()` 之前设置为 daemon。**

后台线程会在所有线程（含 main 线程）结束前一直运行，后台线程可以创建新的线程，但这些线程即使不被显式的声明为后台线程，也会以后台线程的形式执行。

后台线程的管理是一个问题，因此并不推荐使用。

<br/>

### 线程挂起 join()

Join 的作用是当一个线程内生成一个新的线程时，先完成新的线程，原线程阻塞，直至新的线程完成或超时后，原线程继续。

例如，在 A 线程中启动了线程 B（或者 A 可以了线程 B 的引用），当在 A 线程中执行 `B.join()` 的话，A 线程将被阻塞，直至 B 线程完成。

可以对 join() 提供超时设置。

如下例，在 MyRunnable2 中生成了线程 MyRunnable，当 countDown = 3 时，MyRunnable2 会被挂起，直至 MyRunnable 执行完成。

```java
public class MyRunnable2 implements Runnable {
    protected int countDown;

    public MyRunnable2(int countDown) {
        this.countDown = countDown;
    }

    @Override
    public void run() {
        Thread t = new Thread(new MyRunnable(5));
        t.start();

        while (countDown-- > 0) {
            System.out.printf("%s (%s)\n", Thread.currentThread(), countDown > 0 ? countDown : "Liftoff!");

            if (countDown == 3) {
                try {
                    t.join();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }

            try {
                Thread.sleep(100);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
    }
}
```

输出，可以看到 Thread-0 的 countDown = 3 时，被阻塞。直至 Thread-1 线程完成后，才继续执行。

```
Thread[Thread-0,5,main] (4)
Thread[Thread-1,5,main] (4)
Thread[Thread-1,5,main] (3)
Thread[Thread-0,5,main] (3)
Thread[Thread-1,5,main] (2)
Thread[Thread-1,5,main] (1)
Thread[Thread-1,5,main] (Liftoff!)
Thread[Thread-0,5,main] (2)
Thread[Thread-0,5,main] (1)
Thread[Thread-0,5,main] (Liftoff!)
```



### 捕获线程异常

由于线程的特性，不能通过一般的 try-catch 捕获线程逃逸的异常，需要为线程指定 `UncaughtExceptionHandler` 去处理线程异常时的问题。



定义一个 `ThreadFactory`，为所有线程添加 `UncaughtExceptionHandler`

```java
public class MyThreadFactory implements ThreadFactory {
    @Override
    public Thread newThread(Runnable r) {
        Thread t = new Thread(r);
        t.setUncaughtExceptionHandler(new MyExceptionHandler());
        return t;
    }
}
```

定义一个会抛出异常的线程任务

```java
public class MyExceptionThread implements Runnable {
    @Override
    public void run() {
        System.out.println("Runnable Start");
        throw new RuntimeException("Haha, You cannot catch me");
    }
}
```

定义 `UncaughtExceptionHandler` 的处理过程

```java
public class MyExceptionHandler implements Thread.UncaughtExceptionHandler {
    @Override
    public void uncaughtException(Thread t, Throwable e) {
        System.out.println("Catch Exception, from " + t.getName());
        System.out.println("Exception content is " + e.getMessage());
    }
}
```

执行

```java
public class TestException {
    public static void main(String[] args) {
        ExecutorService es = Executors.newFixedThreadPool(10, new MyThreadFactory());
        es.execute(new MyExceptionThread());
        es.shutdown();
    }
}
```

输出

```
Runnable Start
Catch Exception, from Thread-0
Exception content is Haha, You cannot catch me
```



## 共享资源

多线程在合作执行时，并非互相独立互不干扰的。有一些资源，如数据库、内存引用对象、IO 等等，都可能会由于多线程的合作，需要被共享。

但是，由于多线程的调度的不可控，无法保证线程使用资源的顺序，因此可能会导致值的错误、死锁等问题。

最常见的，就是一个多个线程同时修改一个变量，最终导致变量的值异常。



**共享资源的本质，就是序列化访问共享资源，即给定的某个时刻，有且仅有一个任务可操作（读或写）资源。**

<br/>

### 锁，互斥量(mutex)

要实现序列化访问，最常用的便是锁，由于锁会造成操作互斥，因此也被称为互斥量（mutex）。

共享资源一般是以对象形式存在的内存片段，每个对象的结构头中包含了锁的标志位。

Java 提供了关键字 `synchronized` 关键字来提供锁的功能。`synchronized` 可以对不同粒度的对象上锁，无法获得资源锁的任务，将被阻塞。可以通过 `yield()` 和 `setPriority` 提供调度建议。

所有对象均含有单一锁（又称监视器），若锁对象，则在该锁完全释放前，其他任务将阻塞。

当然也可以直接锁整个类，只需要在该类中声明一个 `static` 对象，并对其上锁即可。



锁的使用，一般流程如下：

1. 检查锁是否可用
2. 获取锁
3. 执行代码
4. 释放锁



`synchronized` 关键字要求对象的域被设为 `private`，否则会被其他对象直接访问该值，会造成冲突。

同一任务允许多次获得某一对象的锁，锁被获得的次数，将由 JVM 提供计数。直至对象被上锁的计数变为 0，对象方可被其他任务所使用。







## 线程的生命周期



## 管理线程池

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

`Executors` 提供多种线程池的创建，有如下几种：

| Pool                          | Instance                            | Description                                                  |
| ----------------------------- | ----------------------------------- | ------------------------------------------------------------ |
| SingleThreadExecutor          | FinalizableDelegatedExecutorService | 容量为 1 的线程池，保证同一时间仅有一个线程执行，线程执行顺序同线程被添加入队列的顺序 |
| CacheThreadPool               | ThreadPoolExecutor                  | （推荐）适用于短期内大量异步线程的情况。为每个任务都创建一个线程，每次有新的任务时，都会尽可能复用池中已创建的线程，若池中线程不足，则会创建新的线程。当线程内线程一分钟不被复用，则将被销毁。 |
| FixedThreadPool               | ThreadPoolExecutor                  | 预先执行固定数量的线程分配，可以限制一定时间内同时执行的线程数。若线程池满，则新进入的线程将等待，直至有线程结束或被终止。等待的线程由一个无界队列维护。 |
| ScheduledThreadPool           | ThreadPoolExecutor                  | 创建一个固定容量的线程池，用于周期性调用池中任务。可以参考 [Spring 的 Schedule](http://wenchao.wang/2016/12/23/Spring%20Task%20%E4%B8%8E%20Quartz%20%E8%BF%9B%E9%98%B6/) 和 Quartz |
| SingleThreadScheduledExecutor | DelegatedScheduledExecutorService   | 同上，但只维护容量为 1 的池，因此多个任务时，任务会等待      |
| WorkStealingPool              | ForkJoinPool                        | 多核编程时使用，可以针对核数创建多个队列，实现并行。默认维护 JVM 可用核数的队列数，每个队列维护一定的任务 |

<br/>

