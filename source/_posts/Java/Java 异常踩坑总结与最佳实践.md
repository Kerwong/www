---
title: 'Java 异常踩坑总结与最佳实践'
comments: true
date: 2015-06-02 20:29:14
tags: 
- Java
- 最佳实践
---

Java 编程时，总会遇到可预见或不可预知的异常情况，程序如何处理好这些异常是保证程序稳定健壮的无比重要。对于 Java，通过 `Throwable` 类的众多子类来描述程序遇到的各类异常，主要分为 `Exception` 和 `Error`。

- `Error`: 一般指虚拟机相关问题，如系统崩溃，内存不足，调用栈溢出等严重问题，需要程序终止解决。
- `Exception`：程序可预测解决的异常，如访问异常文件导致的 IO 异常，或者用户自定义的异常，此类异常通过合理处理，可不造成程序中断，保障了程序健壮性。`Exception` 中最主要的，又分为：
  - 检查异常（checked exception）：若抛出此异常，方法后必须强制以 `throws` 关键字进行抛出声明，例如 `IOException` 等
  - 非检查异常（unchecked exception）：无需抛出声明，**`RuntimeException` 均属于非检查异常**，例如 `NullPointerException`, `IndexOutOfBoundsException` 等。

![](http://img.wenchao.wang/20190216213619_aHQNrQ_bVbbdL7.jpeg)



对于如何处理异常，Java 采用的方法就是 `try...catch...finally` 。`try` 所括代码，称为监控区域（guarded region），该区域内所有代码抛出的异常，会被 `catch` 中匹配的 `Exception` 分支所捕获，此处父类可捕获子类异常，最后在 `finally` 中处理收尾。

 `try...catch...finally`  本身不难理解，但原理上也有一些需要注意的地方，下文也总结了些使用技巧。



<!--more-->

<br/>

# 原理剖析

讨论  `try...catch...finally`  的原理，最主要的是分析 `throw` 和 `return` 的最终状态。以下段代码举例：

*例一：*

```java
void test1() {
    try {
        test2();
    } catch (Exception e) {
        throw new RuntimeException("test1 - catch");
    } finally {
        throw new RuntimeException("test1 - finally");
    }
}

void test2() {
    throw new RuntimeException("test2");
}

public static void main(String[] args) {
    Main main = new Main();
    main.test1();
}
```

最终，这段代码返回的会是那一个异常呢？答案是 `finally` 中的那句

```
java.lang.RuntimeException: test1 - finally
	at com.example.Main.test1(Main.java:20)
	at com.example.Main.main(Main.java:30)
```

<br/>

再来看，若  `try...catch...finally`  中，每个代码块均含有 `return`，那么返回什么呢？看下例：

*例二：*

```java
int test1() {
    int i = 0;
    try {
        System.out.println("test1 - " + ++i);
        test2(i);
        System.out.println("test1 - " + ++i);
        return ++i;
    } catch (Exception e) {
        System.out.println("test1 - catch - " + ++i);
        return i + 10;
    } finally {
        System.out.println("test1 - finally - " + ++i);
        return i + 100;
    }
}

void test2(int i) {
    System.out.println("test2 - " + i);
    throw new RuntimeException("test2");
}

public static void main(String[] args) {
    Main main = new Main();
    System.out.println(main.test1());
}
```

返回如下，结果是 finally 中的返回值。

```
test1 - 1
test2 - 1
test1 - catch - 2
test1 - finally - 3
103
```

<br/>

可以注意到， <u>`finally` 语句块是在**控制转移语句**之前执行的</u>，控制转移语句有 `throw`, `return` 。

这是因为，在 Java 虚拟机编译 `finally` 语句块时，会把 `finally` 语句块作为[子程序](https://zh.wikipedia.org/wiki/%E5%AD%90%E7%A8%8B%E5%BA%8F)，直接插入到 `try` 语句块或者 `catch` 语句块的控制转移语句之前。

<br/>

除了执行顺序，还有一点不可忽视，就是在例一、例二中，程序最终获得的是 `finally`中抛出的异常以及返回值。这是因为，在执行 `finally` 之前，`try` 或者 `catch` 语句块会将其返回值保存到本地变量表（Local Variable Table）中。待 `finally` 执行完毕之后，再恢复保留的返回值到操作数栈中，然后通过 `return` 或者 `throw` 语句将其返回给该方法的调用者（invoker）。

<br/>

那么，若出现控制转移语句的冲突时，以谁为准呢？我们是无法在一个块语句中，同时定义 `return` 和 `throw` 的，编译器会提示错误，因为这两条语句是无法都执行的。这里所指的冲突，是当 `try...catch` 中的控制转移语句与 `finally` 中的同时出现了怎么办？

看以下例子：

*例三：*

以下代码会**正常返回**，不会抛出异常。

```java
int test1() {
    int i = 0;
    try {
        System.out.println("test1 - " + ++i);
        test2(i);	// 同上
        System.out.println("test1 - " + ++i);
        return ++i;
    } catch (Exception e) {
        System.out.println("test1 - catch - " + ++i);
        throw new RuntimeException("test1 - catch");
    } finally {
        System.out.println("test1 - finally - " + ++i);
        return i + 10;
    }
}
```

```
test1 - 1
test2 - 1
test1 - catch - 2
test1 - finally - 3
13
```

以下代码**会抛出异常**

```java
int test1() {
    int i = 0;
    try {
        System.out.println("test1 - " + ++i);
        test2(i);	// 同上
        System.out.println("test1 - " + ++i);
        return ++i;
    } catch (Exception e) {
        System.out.println("test1 - catch - " + ++i);
        return i + 10;
    } finally {
        System.out.println("test1 - finally - " + ++i);
        throw new RuntimeException("test1 - finally");
    }
}
```

```
test1 - 1
test2 - 1
test1 - catch - 2
test1 - finally - 3
Exception in thread "main" java.lang.RuntimeException: test1 - finally
	at com.example.Main.test1(Main.java:26)
	at com.example.Main.main(Main.java:37)
```

根据例三，可以发现，当控制转移同时出现时，是以 `finally` 中的为准的，无论该控制转移是 `return` 还是`throw`。

<br/>

以上几例可以看到，`finally` 中的控制转移语句会影响到返回值和返回的异常栈，那若 `finally` 不含 `return` 和 `throw` 呢？会对结果产生什么影响呢？看看例四：

```java
int test1() {
    int i = 0;
    try {
        System.out.println("test1 - " + ++i);
        test2(i);
        System.out.println("test1 - " + ++i);
        return ++i;
    } catch (Exception e) {
        System.out.println("test1 - catch - " + ++i);
        return i;
    } finally {
        System.out.println("test1 - finally - " + ++i);
    }
}
```

```
test1 - 1
test2 - 1
test1 - catch - 2
test1 - finally - 3
2
```

可见，`finally` 中 `i` 已经是 **3** 了，但返回值还是 **2**。这是因为 `finally` 中的控制转移语句会修改本地变量表中的返回值和异常栈，但其他情况，是无法修改已经保存在本地变量表中的返回值和异常栈的，因此，`finally` 中对 `i` 的变更，不会体现在返回值上。这是需要注意的！

<br/>

根据以上实例，可以总结到：

1. `finally` 语句块是在**控制转移语句**（仅针对 `try...catch...finally` 块而言，块外的程序转移不在讨论范围之内）之前执行的，控制转移语句有 `throw`, `return` 
2. 在执行 `finally` 之前，程序会将 `try` 或者 `catch` 中的**返回值**和**异常栈**存入本地变量表
3. 若 `finally` 中无控制转移语句（return 和 throw），则程序返回之前本地变量表中的返回值和异常栈；
   1. 需要注意的是，若`finally`  中无控制转移语句，那么即使在 `finally` 中变更返回的变量的值，是不会影响返回值的。
   2. 若 `try...catch` 也不涉及控制转移语句，程序将顺序执行，`finally` 中对**方法内变量**的变更均有效
4. 若 `finally` 中含有控制转移语句，则以 `finally` 中的控制转移语句为准，即无论 `finally` 中含有 `return` 还是`throw`，均以该语句为准，会覆盖原本地变量表中的返回值或异常栈的内容。



<br/><br/>

# 最佳实践

Java 的异常处理其实并不难，明白后总结了以下几点实践经验。

<br/>

## 准确定义

尽可能准确匹配的定义捕获异常，不要一刀切的处理。这样会掩盖诸多开发时未意识到的问题，这是非常危险的。

### Tip1: 永远不要直接 `catch(Throwable e)`

Java 异常中的 `Error` 也继承 `Throwable`，若直接捕获 `Throwable` 要么会掩盖一些 JVM 造成的错误，又或者造成代码无法按计划执行（有些 JVM 错误不会被 `catch`捕获，和开发人员预想逻辑相违背）。

<br/>

### Tip2: 准确 `throws` 检查异常

当需要 `throws` 时，不要将异常定义过泛，定义过泛会破坏检查异常的意义。若直接 `throws Exception`，那么代码如果需要抛出其他的检查异常，上层调用永远无法知道

```java
// 不推荐
void test() throws Exception {}

// Correct!    
void test() throws SpecException1, SpecException2 {}
```

<br/>

### Tip3: 明确 `catch`的异常类型

当需要 `catch` 时，需要明确捕获异常类型。若只是泛泛的 `catch(Exception e)`，会造成：

1. 若底层重构，抛出其他类别的异常时，也会被简单的捕获，无法被上层感知
2. 模糊了程序逻辑，掩盖了可能存在的未被开发人员考虑到的问题

```java
// 不推荐
try {
    // do something
} catch (Exception e) {}

// 推荐
try {
    // do something
} catch (SpecException1 e) {
} catch (SpecException2 e) {}
```

<br/>

## 妥善处理

异常栈包含着丰富的信息，帮助开发人员定位问题。

因此最佳的异常栈，应该由问题发生处抛出，不应该被肆意的覆盖或者“吞食”；抛出的异常栈，需要合理的输出，能妥善的告知开发人员进行问题的定位。

### Tip4：早 `throw` 晚 `catch`

编码时，应该尽早抛出异常，并在有足够信息后再捕获异常进行妥善处理。

如果有些异常暂时无法处理，不要为了`catch` 而`catch`，而应该继续 `throw`。

<br/>

### Tip5: 吞食有害 harmful if swallowed

《Java 编程思想》中提到，“被检查的异常” 的处理方法是方法后面跟着 throws 显式声明的异常。这会强制让开发人员在未就绪时处理这个错误，有时开发人员为了“取巧”，经常会 swallow it，这不是太好的设计。所谓 “swallow” 是如下代码

```java
void test() {
    try{
        method();	// throws checked exception
    } catch (Exception e) {
        System.out.println("exception");	// exception 被“吞”，异常栈不再能被追溯
    }
}
```

此时，检查的异常被不合理的处理了，会导致难以排查问题。

若出现暂时不想处理，不要随意的用 `try...catch...finally` 进行处理，可以有两种办法，一是可以将异常包入 `RuntimeException()` 中处理：

```java
void test() {
    try{
        method();
    } catch (Exception e) {
        throw new RuntimeException(e);
    }
}
```

二是继续 `throws` 抛出，由更上层调用进行处理。

<br/>

### Tip6：维护异常栈信息，切勿轻易丢弃

有时开发人员会自定义异常类，切记合理包装异常栈，不要轻易丢弃。如下，自定义的 `MyException` 异常类，构造函数允许仅接收字符串，但在 `throw new MyException(e.getMessage())` 时，`e.getMessage()` 会丢失异常栈信息。

```java
class MyException extends RuntimeException {
    MyException(String msg) {
        super(msg);
    }

    MyException(Throwable e) {
        super(e);
    }
}

void test() {
    try {
        // do something
    } catch (Exception e) {
        // 不推荐
        // throw new MyException(e.getMessage());
        
        // 推荐
        throw new MyException(e);
    }
}
```

又或者底层方法抛出了异常 `SpecException1`，但在上层调用捕获后，开发人员又以 `SpecException2` 抛出了。那么就丢失了 `SpecException1` 抛出时的异常栈，问题定位就不够准确了。若有额外补充异常信息的需求，也请将异常栈一同传递。如下举例

```java
// 不推荐
try {
	// do something
} catch (SpecException1 e) {
    throw new SpecException2("some info");
}

// 推荐
try {
	// do something
} catch (SpecException1 e) {
    throw new SpecException2("some info", e);
}
```

<br/>

### Tip7: 过犹不及，一条异常不要输出两遍。要么记录，要么抛出，不要一起执行

tip6 告诫不要轻易丢弃异常栈，但是这一条告诫也不要过多的输出异常信息。

这是因为过多的输出，会对开发人员造成混淆，不利于日志的分析（往往是自动化进行）。当异常信息过多时，还要去分辨是不是同一个异常造成的，太浪费时间了。

简单的讲，一条异常不应该输出多遍。开发人员一般不会在同一代码块中多次输出异常。但可能会有以下情况：

```java
// 不推荐
try {
    // do something
} catch (SpecException1 e) {
    logger.debug("exception: " + e);
    throw e;
}
```

以上代码，既对异常进行了日志输出，又再一次抛出了异常。

抛出异常的目的，是为了被上层调用捕获，由于上层调用并不知底层调用已经对异常进行了输出（底层封装和上层调用并非由同一开发人员完成），往往会在此对异常进行再次的输出。

又或者，由框架默认统一处理了抛出的异常。总之，造成异常输出两遍。

这需要避免。

<br/>

### Tip8: 异常应由一行日志代码输出

将一个异常，分多条日志输出。日志不多时，可能还可以保证两条日志的连续性。但服务往往是多线程，日志也可能归集了分布式服务的信息，这造成代码中连续的输出，实际在日志文件中相隔成千上万行，难以排查问题。

因此建议，将异常在一条日志代码中输出。

```java
// 不推荐
try {
    // do something
} catch (SpecException1 e) {
    logger.debug("exception: " + e.getMessage());
    logger.debug("trace: " + e);
}

// 推荐
try {
    // do something
} catch (SpecException1 e) {
    logger.debug("exception: " + e.getMessage() + "， trace: " + e);
}
```

<br/>

### Tip9: 不要只是简单的打印异常

不要只是简单的将异常打印。如果是调用的方法，简单的打印异常，上层调用并无法感知，而认为调用正确，这会造成更多的异常发生。

一定要妥善处理。

如果异常抛出到最上层，那么可以打印，但也不要直接将异常直接抛给用户。因为这样的信息，对用户而言是没有任何意义的，甚至可能暴露了系统的问题，给攻击者可乘之机。

因此，可以在系统最上层调用中，统一打印异常，并将异常进行封装，转换为用户可理解的错误信息。

<br/>

## 关注 `finally` 

### Tip10: `finally` 中不要`return` 和 `throw`

看了之前的原理剖析，可以知道 `finally` 中的 `return` 和 `throw` 会覆盖 `try...catch` 中的值。

因此不建议在 `finally` 中 `return` 或 `throw` 。但有时，`throw` 会比较隐蔽，例如以下代码，`method2` 可能在调用是抛出异常，若不处理，就会覆盖 `method1` 抛出的异常。因此，需要用 `try...catch...finally` 再次包一下。

```java
// 不推荐
try {
    method1();
} finally {
    throw new MyException();
}

// 需关注 method2
try {
    method1();
} finally {
    method2();
}

// 推荐
try {
    method1();
} finally {
    try {
        method2();
    } catch (SpecException e) {
        // do something
    } finally {
        // do something
    }
}
```

<br/>

### Tip11: 记得在 `finally` 中释放资源

记得在 `finally` 中释放资源，避免资源浪费。一般是释放管道、连接等。

或者使用 Java 7 的写法：

```java
try(open the resouces) {
    // do something
}
```

<br/>

## 其他注意点

### Tip12: 不要将 `try...catch...finally` 作为流程控制

这会导致代码混乱不堪，难以阅读，重构困难。异常处理不是这么用的！为了同事的发际线，请珍惜这段缘。

<br/>

### Tip13: 巧妙的使用模板代码，避免 `try...catch...finally` 的冗余

常见的是文件的开启关闭，数据库连接的开启和关闭等。例如：

```java
class DBUtil{
    public static void closeConnection(Connection conn){
        try{
            conn.close();
        } catch(Exception ex){
            //Log Exception - Cannot close connection
        }
    }
}

public void dataAccessCode() {
    Connection conn = null;
    try{
        conn = getConnection();
        // do something
    } finally{
        DBUtil.closeConnection(conn);
    }
}
```

<br/>

### Tip14: 异常对性能的影响

处理异常对 JVM 而言，是比较消耗性能的，因为需要额外的去维护异常栈。

调用一个抛出异常的方法的资源消耗，要比调用一个一般方法多。

因此，需要平衡好异常抛出的层级，避免过多层级的异常栈传递。更要注意，在循环中的异常。

<br/>


### Tip15: JavaDoc 注释说明

注释不规范，同事泪两行。

虽然我觉得优秀的程序员写的清晰富有逻辑的代码，足以说明代码所解决的问题。但实际生产中，往往是过高的要求了。所以，还是写好代码注释吧。

参考 JDK 代码注释来写，使用 `@throws`，例如以下是 `java.io.File.java` 中的一段

```java
/**
* Atomically creates a new, empty file named ...
*
* @return  <code>true</code> if the named file does not exist and was
*          successfully created; <code>false</code> if the named file
*          already exists
*
* @throws  IOException
*          If an I/O error occurred
*
* @throws  SecurityException
*          If a security manager exists and its <code>{@link
*          java.lang.SecurityManager#checkWrite(java.lang.String)}</code>
*          method denies write access to the file
*
* @since 1.2
*/
public boolean createNewFile() throws IOException {}
```

<br/>

# 总结

Java 的异常处理，使用并不困难，难点在于实践中的把握。

理解了 `finally` 原理，记住早 `throw` 晚 `catch` 的准则，有助于帮助提高代码质量，提高排查问题的效率。

最佳实践是我参考网上文章，加之以总结的结果，随着日后的实践，会逐渐补充。

<br/>

# 参考资料

[1] 《Java 编程思想》
[2] 关于JAVA异常处理的20个最佳实践，作者[**超人归来**](https://segmentfault.com/u/chaorenguilai)， https://segmentfault.com/a/1190000015028573 
[3] 如何优雅的处理异常(java)？知乎网友，https://www.zhihu.com/question/28254987
[4] Java 异常处理的误区和经验总结，作者赵爱兵，https://www.ibm.com/developerworks/cn/java/j-lo-exception-misdirection/index.html
[5] 关于 Java 中 finally 语句块的深度辨析，作者魏成利， https://www.ibm.com/developerworks/cn/java/j-lo-finally/index.html
[6] 深入理解java异常处理机制，作者规速，https://blog.csdn.net/hguisu/article/details/6155636
[7] Top 11 Java Exception Best Practices， 作者 Krishna Srinivasan，https://javabeat.net/java-exception-best-practices/