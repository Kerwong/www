---
title: '探索 Java 中 String 的本质，从 char 说起'
date: 2015-6-17 21:11:09
tags: 
- Java
- JVM
- 最佳实践
---

`String` 类可以认为是 Java 语言中最为常用的类了，对于 `String` 的理解更是 Java 面试题的常客。
但作为一个 Java 程序员，对于 `String` 是否足够了解了呢？
本篇文章将对 `String`的存储，使用做一个详细的探讨。
<br/>
先来简单介绍下 `String`，`String`是 JDK 提供的位于 `java.lang` 中的基础类，但区别于 `byte，short，int，long，char，boolean，float，double`这些基本类型，`String`不是基本数据类型，而是一个类。
因为是类，实例化的`String` 对象的空值为 `null`，但`String`是如此常用，于是 JDK 对其有特殊的优化。
<!--more-->
<br/>

# String 的存在形式
上文提到，`String`是 JDK 提供的类，要学习 JDK，最好的方法就是阅读其源码。

```java
public final class String
    implements java.io.Serializable, Comparable<String>, CharSequence {
    /** The value is used for character storage. */
    private final char value[];
    ...
```
分析源码可以知道，Java 中`String` 是以 `char 数组`的形式存在的。
<br/>

## 讨论下 Java 中的 char 类型
`char` 基本数据类型是 Java 中用于存储字符的。`String` 就是以 `char数组`形式存储的，要理解 `String` 就必须先了解 `char`。
但在讨论 `char` 之前，还需要介绍另外两点知识。
<br/>

### 编码 unicode vs UTF
unicode，称为统一字符编码，是国际上对千奇百怪字符的统一的**编号**。unicode 最初的 256 个字符，是继承于 ASCII 编码。例如英文字母 `a`，在 unicode 中编号为 97，中文 `我` 字，在 unicode 中的编号就是 25105。简单的说，unicode 就是统一的字符编号。但是，这么多字符如何在代码中表示呢？这便是 UTF。

<br/>

UTF，unicode 转换格式(Unicode Transformation Format)，UTF 有多种编码方式，比较常用的就是 `UTF-8` 和 `UTF-16`，这两者各有优劣，`UTF-8` 信息密度更高，传输、存储效率更高，`UTF-16`字符对齐，易于程序处理，利于优化计算效率。使用应视情形而定。

- `UTF-8` 是通过变长来表示 unicode 字符的，以 byte 为单位，长度范围 1~6。例如 `a` 编号是 97，就用一个 byte，也就是 8 bit 来编码，而 `我` 的编号是 25105，一个 byte 无法编码，于是就用 2个 byte 来编码。
- `UTF-16` 则是固定长度编码。统一用 2 byte，也就是 16bit 进行编码，但 unicode 当前字符集已经超出 16bit 所能编码范围了(16bit，可对 2^16 = 65536 个字符进行编码)，因此也会用 4 byte 来表示。



<br/>

### 内码与外码
内码 internal encoding，外码 external encoding
- 内码是语言运行时，`char` 在内存中的编码方式。
- 外码是除了内码以外的编码，例如源码编译生成的目标文件(可执行文件、.class 文件)中的编码均为外码。

<br/>

### 那么 Java 中的 char 呢？
`char` 是 Java 的基本类型之一，用来表示字符。
JVM 采用的内码，是 `UTF-16`，也就是说 **Java 中的 char 的长度为 2 byte，即 16 bit**。
但上文提到，仅 16 bit 已无法表示所有的 unicode，因此为了向下兼容，Java 的 char 保留为 16bit，若有无法用 16 bit 表示的字符，则采用 2 char，即 4 byte，32 bit 来表示。

> Java 的 class 文件采用 UTF-8 存储字符。`char` 在 class 中以 `UTF-8` 方式编码，区别于内码中的 `char`

<br/>

### `Character`，关于 `char` 的更多
Java 采用 `UTF-16` 为字符编码。但 unicode 字符集已经超出 16bit 所能表述的范围，因此有些字符会采用 2char，即 32 bit 进行编码。
为了方便处理，Java 提供了 `Character` 类。`Character` 对 `char` 进行了封装，并提供了一些方法，主要是`char` 类型的判断（是数字还是中文）、大小写装换、比较等等。具体方法，可以参考 JDK 源码`java.lang.Character`。
<br/>
提到 `Character`，主要是强调以下几点：
1. `code point` vs `code unit`
  码位 `code point`：指字符在 unicode 字符集中的编号，用 `int` 表示，int 为 32bit，现阶段可表示 unicode 字符集。范围为 `U+0000 ~ U+10FFFF`。
  `code unit`：对应一个 `char`，可由 1个或 2个 `code unit` 组成 `code point`。这两个概念主要涉及 `UTF-16` 实现。

2. 基本多语言平面 `Basic Multilingual Plane (BMP)` vs 辅助平面 `Supplementary Character`
  这两个概念，是针对 unicode 字符集而言。当前 Java 支持的 unicode 字符集范围为 `U+0000 ~ U+10FFFF`，若超出此范围，则无法处理。
  `Basic Multilingual Plane (BMP)`：用于表示 `U+0000 ~ U+FFFF` 范围的字符。
  `Supplementary Character`：unicode 超出 `U+FFFF` 范围后，需要用 2个 char 表示，超出部分称为 `Supplementary Character`，由于 `code point` 范围最大为 `U+10FFFF`，所以 `Supplementary Character` 最多为 5bit，高位的 11bit 必须均为 0，否则表示字符超出 Java 当前字符集范围。处理单个 `char`时，不需要使用 `Supplementary Character`，当以 `int` 表示字符时，才需要使用。
  具体可参考维基百科  [UTF-16](https://zh.wikipedia.org/wiki/UTF-16) 介绍。


<br/>


## String 是 char[]
以上分析源码，知道了 `String` 是以 `final char[]` 的形式存储的，并且知道了由于 Java 采用 `UTF-16` 编码 unicode，因此有些字符由 2 char 表示。

```java
int len1 = "1".length();  // = 1
int len2 = "我".length();  // = 1
int len3 = "😂".length(); // = 2

// 用以下方法获得真正的 unicode 字符个数
String emoji = "😂";
int len3 = emoji.codePointCount(0, emoji.length());
```
`String` 类中还提供了一些常用的字符处理方法，将在下面的实践章节进行介绍，让我们下来看看 `String` 是如何在 JVM 中存储的。
<br/>

# Java 中 String 的存储
1. `String` 底层是 `final char[]`，是常量。在 JVM 中，位于**字符串常量池**。所谓常量，就是一旦创建，就不无更改。
2. 只要 `String` 的值发生变更，Java 的处理方式是新建一个 `String`对象。
3. 由于 `String` 是类，其实例为对象。Java 在处理对象传递是，均是**引用拷贝**。
4. 对 `String` 的只读，任何引用均不会修改其值。

<br/>

> JDK1.7 中 JVM 把`String`常量池从方法区中移除了；JDK1.8 中 JVM 把`String`常量池移入了堆中，同时取消了“永久代”，改用元空间代替（Metaspace）
>
> 运行时常量池中的内容，主要源于 class 静态常量池，也就是编译阶段确定的常量池。但也可以通过 `String.intern()` 方法，手动将字符串常量放入运行时常量池中，否则 JVM 不会主动添加常量至常量池。



## 为何选择常量池存放 `String`
常量池是为了避免频繁的创建和销毁对象而影响系统性能，其实现了对象的共享。
例如字符串常量池，在编译阶段就把所有的字符串文字放到一个常量池中。
1. 节省内存空间：常量池中所有相同的字符串常量被合并，只占用一个空间。
2. 节省运行时间：比较字符串时，`==` 比 `equals()`快。对于两个引用变量，只用`==`判断引用是否相等，也就可以判断实际值是否相等。
<br/>

## `String` 何时为常量，入常量池
何时视为常量，何时入常量池？先了解什么是常量表达式和 `==` 与 `equals()` 的区别吧。
### 常量表达式
要解决这个问题，要先理解常量表达式。
`常量表达式`：指代表基本数据类型或者 `String` 数据类型的表达式，能在**编译期间能计算出来的值**，因此表达式中的均需为常量，不可为变量。
对于常量表达式，Java 编译时会进行优化，直接赋予计算后的常量值。
<br/>

### `==` 和 `equals()`
- `==` ： 判断两个对象是否为同一对象，即判断引用的是否为同一个对象。
- `equals()`：判断两个对象的值是否相同。类中默认的 `equals()` 同 `==` 判断，但可被自定义覆盖。
<br/>

### 举例
了解了常量表达式，来看看下面的实例。

```java
private final static String staticA = "AAA";   // 常量
private final static String staticB = "111";   // 常量
private final static String staticC;
private final static String staticD;
private final static String staticE;
static {
    staticC = "AAA";
    staticD = "111";
    staticE = "AAA111";
}

public static void main(String[] args) {
    String str0 = "AAA111";
    String str1 = "AAA" + "111";
    String str2 = staticA + staticB;
    String str3 = staticC + staticD;
    String str4 = "AAA" + 111;
    String str5 = staticA + 111;
    String str6 = staticC + 111;
    String str7;
    str7 = staticC + staticD;
    String str8;
    str8 = str7 + "";
    
    String str9 = str8.intern();
    System.out.println(str0 == str8);	// true
}
```
看如下代码，其中 `str0~str8` 的值均为 `AAA111`。
但当彼此进行 `==` 操作时，却不均为 `true`，说明底层并未指向相同的对象。
<br/>
`staticE, str0, str1, str2, str4, str5,str9` 彼此进行 `==` 判断时，为 `true`。
`staticA == staticC，staticB == staticD` 为 `true`。
`str3, str6, str7, str8` 彼此均为 `false`。

![](http://img.wenchao.wang/20190310212850_gIYMfF_Screenshot.jpeg)
此图为 Java8 示意，Java8 之前的运行时常量池是在方法区。
<br/>
对以上代码分析：
`staticA ~ staticE` 五个变量，均为 `final`常量。但 `staticC~staticE` 与 `staticA，staticB` 略有区别，`staticC~staticD` 虽然是常量，但在编译期未被赋值，是到运行时才被赋值，因此性质类似于一个变量，不可视为编译时常量。`staticE` 也是变量，但赋值直接为 `AAA111`。

`str0~str8` 部分，均为栈内定义的变量。
1. `str0` 在编译时，直接赋值，执行的是常量表达式。`AAA111` 入常量池，str0 为其引用。
2. `str1` 在编译时，是由两个常量 `AAA` 和 `111` 连接所得，值也可以确定。由于 `str0` 时，已经将 `AAA111` 放入常量池，因此 `str1` 复用，引用同一常量池对象。
3. `str2` 是 `staticA` 和 `staticB` 连接，由于 `staticA，staticB` 值是常量，执行的是常量表达式，引用常量池。
4. `str3` 是 `staticC` 和 `staticD` 连接，但  `staticC` 和 `staticD` 未被直接赋值，编译期无法决定值。
5. `str4` 和 `str5` 均能在编译期决定值，因此也引用常量池
6. `str6~str8` 均无法在编译期决定值，因此不引用常量池。
7. `str9` 使用了 `String.inertn()`，**若字符串已在常量池存在，则引用已有常量池对象，若不存在，则会手动将字符串放入字符串常量池，并引用**。

<br/>
讨论完常量池的情况，再来看看堆的情况。
```java
String sA = "ABCD";
String sB = new String("ABCD");
String sC = new String("ABCD").intern();
System.out.println(sA == sB);   // false
System.out.println(sA == sC);   // true
System.out.println(sB == sC);   //false
```
如上代码，当 `new` 一个对象时，Java 会将其放置于堆中。因此，显然不会与常量池中的引用相等，`sA == sB` 为 false。
但如上文所述，如果主动调用 `String.intern()` 方法，则会将字符串放入常量池，此处 `ABCD` 字符串已存在，因此`sC` 直接引用常量池中的字符串对象。
<br/>
仔细分析可知，在 `new String("ABCD")` 时，可能创建一个或两个对象。若 `new` 的字符串已经存在，则仅会在堆上创建一个对象，但若字符串不存在，则会先在常量池中创建，然后再堆中创建对该字符串的引用。
<br/>

# String 实践
这部分，主要是总结 《Java 编程思想》13章字符串章节。
## JDK 中 `+` 的重载与 `StringBuilder` 优化
由于 `String` 对象的不可变。每次对字符串的变更，均会创建一个新的对象，那么出现下面情况时，会产生大量的中间变量，使得代码效率降低。
```java
String hello = "h" + "e" + "l" + "l" + "o";
```
若不进行优化，上面代码会在字符串常量池中创建 `h, e, l, o, he, hel, hell, hello`，这么多中间对象。
Java 对此进行了优化。
<br/>
以下代码为例
```java
public static void main(String[] args) {
	String str1 = "abc";
	String str2 = str1 + "h" + "e" + "l" + "l" + "o";
}
```
利用 JDK 提供的 `javap -c XXXX` 反编译工具，可以看到底层实现。
```               
0: ldc           #2                  // String abc
2: astore_1
3: new           #3                  // class java/lang/StringBuilder
6: dup
7: invokespecial #4                  // Method java/lang/StringBuilder."<init>":()V
10: aload_1
11: invokevirtual #5                  // Method java/lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/StringBuilder;
14: ldc           #6                  // String h
16: invokevirtual #5                  // Method java/lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/StringBuilder;
19: ldc           #7                  // String e
21: invokevirtual #5                  // Method java/lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/StringBuilder;
24: ldc           #8                  // String l
26: invokevirtual #5                  // Method java/lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/StringBuilder;
29: ldc           #8                  // String l
31: invokevirtual #5                  // Method java/lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/StringBuilder;
34: ldc           #9                  // String o
36: invokevirtual #5                  // Method java/lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/StringBuilder;
39: invokevirtual #10                 // Method java/lang/StringBuilder.toString:()Ljava/lang/String;
42: astore_2
```
可以发现，编译器自动引入了 `StringBuilder` 类，在每次重载 `+` 时，底层均调用一次 `StringBuilder.append()` 方法。这减少了中间对象，提高了效率。

虽然编译器会帮助我们优化，但用 `+` 效率还是比较低。这是因为每次执行字符串 `+`，都会创建 `StringBuilder`对象。
```java
String str1 = "";
for (int i = 0; i < 100; i++) {
    str1 += i;
}
```
对应反编译字节码为，从 6~18 行为循环，第 10行，会创建 `StringBuilder` 对象。在循环中，创建对象，调用了两次 `append()` 方法和一次 `toString()` 方法，效率不高。
```
0: ldc           #2                  // String
2: astore_1
3: iconst_0
4: istore_2
5: iload_2
6: bipush        100
8: if_icmpge     36
11: new           #3                  // class java/lang/StringBuilder
14: dup
15: invokespecial #4                  // Method java/lang/StringBuilder."<init>":()V
18: aload_1
19: invokevirtual #5                  // Method java/lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/StringBuilder;
22: iload_2
23: invokevirtual #6                  // Method java/lang/StringBuilder.append:(I)Ljava/lang/StringBuilder;
26: invokevirtual #7                  // Method java/lang/StringBuilder.toString:()Ljava/lang/String;
29: astore_1
30: iinc          2, 1
33: goto          5
```
因此还是推荐主动创建 `StringBuilder` 对象。可以优化为
```java
String str1 = "";
StringBuilder sb = new StringBuilder();
for (int i = 0; i < 100; i++) {
    sb.append(i);
}
str1 = sb.toString();
```
反编译结果如下，可以看到在循环外创建了一次 `StringBuilder`，并且循环内也只调用了一次 `append()` 方法，最终调用了一次 `toString()`。
```
0: ldc           #2                  // String
2: astore_1
3: new           #3                  // class java/lang/StringBuilder
6: dup
7: invokespecial #4                  // Method java/lang/StringBuilder."<init>":()V
10: astore_2
11: iconst_0
12: istore_3
13: iload_3
14: bipush        100
16: if_icmpge     31
19: aload_2
20: iload_3
21: invokevirtual #5                  // Method java/lang/StringBuilder.append:(I)Ljava/lang/StringBuilder;
24: pop
25: iinc          3, 1
28: goto          13
31: aload_2
32: invokevirtual #6                  // Method java/lang/StringBuilder.toString:()Ljava/lang/String;
35: astore_1
```
<br/>

## 避免 `toString()` 无意识的递归
Java 的所有类均继承于 `Object`，因此所有类均可重写 `toString()` 方法，`toString` 方法常被用于打印对象的基本信息。
但如果在 `toString` 方法中，用到了 `this`，便会出现无限递归，报 `StackOverflowError` 异常。例如以下代码：
```java
public class InfRec {
    @Override
    public String toString() {
        return "InfRec" + this;
    }

    public static void main(String[] args) {
        System.out.println(new InfRec());
    }
}
```
应该将 `this` 改为 `super.toString()`；

<br/>

## `StringBuilder` vs `StringBuffer`
- `StringBuilder`：非线性安全，效率更高，于 Java 5中加入
- `StringBuffer`：线性安全，使用了 `synchronized` 关键字。效率低，不推荐使用，即使是多线程环境，也有更好的方案。

<br/>

> 更多 `String` 使用，参考 JDK 源码

<br/>

# 总结
1. `String` 不是基础数据类型，是一个类，默认值是 `null` 而非 `""`。
2. `String` 是由 `char[]` 构成，Java 内码采用 `UTF-16` 对 unicode 编码。因此存在一个字符长度为 2的情况，如 😂 对应的 `\uD83D\uDE02` 。
3. `String` 为常量，一旦定义不可变更。若修改，会创建新的对象。
4. `String` 传递时为引用拷贝。
5. 通过定义常量或者常量表达式，可以于编译期确定 `String`的值的，会将该字符串放入 class 静态常量池，当类加载时，载入至运行时常量池。
6. 可通过 `String.intern()` 方法，主动将字符串放置入常量池，若常量池已存在该字符串，会直接引用。若不主动调用 `intern()` 方法，JVM 不会主动将字符串放入常量池。
7. `new String("ABCD")` 过程，会创建一个或两个对象，或有一个位于常量池，另一个位于堆中。
8. 当代码涉及较多字符串 `+` 操作时，使用 `StringBuilder` 能提高效率
9. 不要在 `toString` 方法中使用 `this`，避免无限递归，应该用 `super.toString()`
10. `StringBuilder` 非线性安全，`StringBuffer` 使用了`synchronized` 关键字，效率低，不推荐使用。

<br/>

# 参考资料
[1] 深入理解Java虚拟机：JVM高级特性与最佳实践（第2版），作者周志明
[2] 《Java 编程思想》第4版，作者 Bruce Eckel
[3] class文件常量池和运行时常量池比对， http://www.ifcoding.com/archives/284.html
[4] 什么是字符串常量池？， http://www.importnew.com/10756.html
[5] Java篇-String详解， TianTianBaby223，https://www.jianshu.com/p/d832752caf0c
[6] Java常用类（二）String类详解， https://www.cnblogs.com/zhangyinhua/p/7689974.html
[7] String类详解， https://juejin.im/post/59f6eb076fb9a045154329cc
[8] Top 10 questions of Java Strings，http://www.programcreek.com/2013/09/top-10-faqs-of-java-strings/
[9] Java中String详解，作者 Lolita， https://zhuanlan.zhihu.com/p/29629508