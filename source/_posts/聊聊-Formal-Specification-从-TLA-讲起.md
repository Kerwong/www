---
title: '聊聊 Formal Specification, 从 TLA+ 讲起'
date: 2017-11-20 13:44:24
tags: 
- TLA+
- Formal Specification
---

第一次听到 `TLA+` 是自大丰哥与德国慕尼黑参加数据库大会时，听了 *Microsoft* 所做汇报时，了解到的。处于大家对此新生事物的好奇，他遍将此作为一项课题，安排于我，因此有幸对 `TLA+` 做进一步的研究。
在研究过程中，随着对 `TLA+` 的了解的逐步加深，我见识到了 *Formal Specification* （以下简称 *Spec*）这个更为广阔的领域。
*Spec* 是一个有着半个世纪历史的研究领域，自从大型机时代，便有了其雏形。那时的软件开发手段并不如现在那样丰富，也缺乏系统性的理论知道，数学家、计算机科学家等致力于为软件系统开发提供更为安全、可靠、HA 的软件系统，在此摸索过程中，遍诞生了 *Spec* 这的研究。
<!--more-->

# 什么是 Formal Specifications
在上个世纪，就是那*Microsoft，Oracle，Cisco* 把持这计算机世界最重要的基础系统和软件（操作系统、数据库、网络）的年代，软件开发变得越来越复杂，大型软件的开发不再是 Bill Gates 以个人之力开发 *DOS*，或者是 *IBM* 拉一批高中生开发一个 OS 那么简单了。
代码的行数指数级增长，没有人能理的清系统到底要干什么？怎么干？干成了没有？

随着问题的日趋严峻，有这么一批“强迫症”数学家 (早年间的计算机科学家，大多都是数学家)，想到了将他们最为熟悉的数学引入到软件开发领域。就如同为软件开发提供一种标准化的模型图纸，和建筑图纸、机械制图一样，通过对软件的每一步，每一个状态的定义，实现对软件功能的精细化、标准化表述。

这，便是 *Formal Specification*

<br />

## Formal Spec 定义
以下是摘自维基百科中对 *Formal Spec* 的定义

> In computer science, formal specifications are **mathematically based** techniques whose purpose are to help with the implementation of systems and software. They are used **to describe a system, to analyze its behavior, and to aid in its design** by verifying key properties of interest through rigorous and effective reasoning tools. These specifications are formal in the sense that they have a syntax, their semantics fall within one domain, and they are able to be used to infer useful information
>
> 摘自 [Wikipedia, Formal Specification](https://en.wikipedia.org/wiki/Formal_specification)

从以上的定义，可以看到以下几个 Key Words：
- Mathematics，具体指离散数学，包括逻辑学、集合论、代数等知识
- Formal，标准的规范
- To describe, to analyze, to verify，*Spec* 可用于软件设计、分析与验收的各个阶段，**注意并非实现**

简单的讲，*Spec* 就是软件系统的说明书，它能指导工程师的开发，也能用于用户最终的验收，但说明书本身并不能实现系统的功能。

> 作为一个新生概念，需要再次强调，**Spec 只能用于描述，不能实现系统功能**

<br />

## Formal Spec 的生命周期
通过定义，我们可以发现，*Spec* 在软件生命中，属于偏前期的工作

![](http://nutslog.qiniudn.com/17-11-21/23592304.jpg?imageView2/0/w/440)

*Spec* 与 *Design* 的关系
![](http://nutslog.qiniudn.com/17-11-21/11006871.jpg?imageView2/0/w/440)

## Formal Spec 的成本
写好一份系统说明书，是要成本的。尤其是引入了一种新的语言，一套全新的思考方式。

![](http://nutslog.qiniudn.com/17-11-21/42609767.jpg?imageView2/0/w/440)

使用 *Formal Spec* 后，虽然 Specification 阶段成本增加，但 Design & Implementation 和 Validation 阶段成本显著下降。

> 以上三图所引用的资料在撰文过程中丢失，如有侵权或知情，请告知

<br/>

## 如何写好 Spec
行文至此，我已经抛出介绍了 *Formal Spec* 这一种理念，但对于读者，尚无法对 *Spec* 有一个感性的认识。诸位莫急，在之前的在公司中关于 *Spec* 的分享中，我深刻意识到，具体实现只是皮毛，要想学会，必须要强化理念的理解。

前文已经讲了 *Spec* 就是软件系统的说明书，那么，如何写好这个说明书呢？在此，我引用软件领域著名的**鸭子类型 Duck Typing** 为例。
> 当看到一只鸟走起来像鸭子、游泳起来像鸭子、叫起来也像鸭子，那么这只鸟就可以被称为鸭子。
> 摘自 [Duck Typing, Wikipedia](https://zh.wikipedia.org/wiki/%E9%B8%AD%E5%AD%90%E7%B1%BB%E5%9E%8B#cite_note-1)

这其中，`走起来像、游起来像、叫起来……①` 这便是对一个事物的 Specification。
但反过来，如果一个事物满足走起来像、游起来像、叫起来像鸭子，那么这个事物一定是鸭子么？答案是否定的，也可能是天鹅或者鸿雁。
可见，以上 Specification 是不够准确的，我们需要加上更多的定语限定。

例如，改为 `走起来像、游起来像、叫起来像鸭子、非国家保护动物、可食用、家禽……②` 的描述，那么基本上就是鸭子了。

为什么在此是 “基本上” 呢？因为可能有朝一日，天鹅或大雁由于数量的剧增，被取消了保护动物的资格，成为人们饲养的食用家禽。因此可见，以上 Spec 虽然无限趋近了，但仍然是存在“缺陷”的。

那么，既然有“缺陷”，我们继续加限定词不就可以了么？进一步改为 `走起来像、游起来像、叫起来像鸭子、非国家保护动物、可食用、家禽、脊索动物门-鸟纲-雁形目-鸭科-鸭属-禽类、DNA=xxxxx……③`，毫无疑问，我们定义了一只鸭子，但也仅仅只定义了一只鸭子。
这样的 Specification 过于死板，丧失了对普遍规律的可用性，当我们用此描述去验证另一只鸭子时，这鸭子由于 DNA 的不一致，反而被排除在外了，而且，过于详细的 Specification 耗费人力物力，例如我们需要验证每一只鸭子的 DNA，那这样的 Specification 得不偿失。

一般来说，好的 Specification，需要满足以下几点：

- Adequate
- Internally Consistent
- Unambiguous
- Complete
- Satisfied
- Minimal

即，要能充分、完整、精确不存疑、准确的描述事物，又必须满足最小原则、限定不存在交集也不存在包含关系。

> 理解如何写好 *Spec* 是理解 *Formal Spec* 原理最重要的部分

<br/>

# Hello TLA+
![](http://nutslog.qiniudn.com/17-11-25/20880664.jpg?imageView2/0/w/300)

至此，已经介绍了什么是 *Formal Spec*。但仍然对此没有感性的认识。
我们要对软件系统进行描述，也知道了如何比较好的描述，但，怎么做？

对于 *Formal Spec* 方法论的具体实践，便是 *TLA+*

<br/>

## Definition of TLA+'s
**`TLA+`**
> A formal specification language based on simple discrete math, or basic set theory. 
> 摘自 TLA+, Wikipedia

一种基于离散数学与集合论的正规严谨的形式化规约语言。

有 *TLA+*, 自然应该有 *TLA*。
**`TLA`**：Temporal Logic of Actions, 指以诸如 $x' = x + 1$ 表示系统属性或状态变化的方法论。现也统称 *TLA+，+Cal，TLAPS，Toolbox*

**`+Cal`** or **`PlusCal`**：language for  writing formal specifications of algorithm. 
简单的说，*+Cal* 是 *TLA+* 的语法糖，是一种更适合*C/C++* 或* Java* 程序员使用的语言，书写类似于伪代码。在 *Toolbox IDE* 中可自动将 *+Cal* 翻译为 *TLA+*。

**`TLC`**：TLC Model Checker, 用于验证 TLA 时序状态的验证工具，是 *TLA+* 的核心工具

**`TLAPS`**：TLA+ Proof System

<br/>

## TLA+ 轶事
*Formal Spec* 作为一个研究分支学科，诞生已经有半个多世纪了，期间诞生过诸多的践行 *Formal Spec* 思想的语言，如 *Z notation、Java Model Language、B-Methods* 等。*TLA+* 相对而言出现的比较晚了。我并没有去深入学习过其他林林总总的*Formal Spec*语言，但一般而言，后来出现或多或少能借鉴前人的经验，规避一些之前设计的不足。

![](http://nutslog.qiniudn.com/17-11-25/73160142.jpg?imageView2/0/w/300 "TLA+ 作者")

*TLA+* 的作者，是分布式领域的大师、大名鼎鼎的图灵奖得主，Leslie Lamport(其个人官网 http://www.lamport.org/
)。Leslie Lamport 另两个为世人所知的成就是发明了 $LaTeX$ (1985) 和 *Paxos* 算法（1998）解决分布式一致性的问题。

*TLA+* 诞生于 1999年，随着 *TLA+* 的发展，Leslie 又推出了 *PlusCal* 语言方便 *TLA+* 的使用，2012年推出 *TLAPS*，在 2014年，*TLA+* 升级到了 2.0版本。

<br/>

## TLA+ 实践
说了这么多，下面来具体介绍一下该如何写一个 *TLA+* 程序。一般来说，共分为六步：
1. 定义系统的初始状态
2. 描述系统可能出现的所有操作和状态
3. 定义恒定量(Invariant) 和时序归约(Temporal Formula), 确定结束状态
4. 通过 IDE 的 *Spec Parser* 验证
5. 设置 *TLC*，对系统常量赋值，对恒定量设置监测等
6. 执行 *TLC*，查看并分析执行结果

此外，还需要了解 *TLA+* 的专属 IDE——*TLA+ Toolbox*。

![](http://nutslog.qiniudn.com/17-11-26/98815720.jpg "Toolbox IDE 截图")

*Toolbox* 是在 *eclipse* 开源框架下编写的 IDE，下载地址在 Lamport 的个人网站 http://lamport.azurewebsites.net/tla/toolbox.html

<br/>

### 以欧几里得算法为例
欧几里得算法，咱们国家又称为辗转相除法，是一个求最大公因数的一个著名算法。要实现此算法，我们先定义一个方法，以判断一个数是否是另一个数的因子

```TLA+
------------ MODULE GCD ------------
EXTENDS Integers
Divides(p, n) == \E q \in Int : n = p * q
====================================
\* Modification History
\* Last modified Sun Nov 26 01:16:17 CST 2017 by wangwc
```
以上是原始的 *TLA+* 代码，未接触过的话，会觉得编程麻烦，可读性差。在之后会进一步介绍 *PlusCal* 语言，可以方便我们的编程。可读性差，可以通过 *Toolbox* 所提供的 *File->Produce PDF Version* 功能，将 *TLA+* 代码以 $LaTeX$ 的形式翻译为数学表达。

效果如下：
![](http://nutslog.qiniudn.com/17-11-26/39204452.jpg)


#### 代码解释
- 第一行：分割线，用来指明 Module 名
- 第二行：`EXTENDS Integers`，`EXTENDS` 是 *TLA+* 的保留字，表示引入一个包。`Integers` 便是 *TLA+* 系统自带的一个包，表示所有整数操作，包括加法、减法、乘法、平方、幂等，**注意，此包不包含除法运算**，因为除法运算可能产生小数，无法通过整数表达。

- 第三行
  - $x\in S:P(x)$ 表示，<u>$x$ 属于集合 $S$，使得 $P(x)$ 表达式成立(为真)</u>
  - `\E` 是 *TLA+* 中对于 $\exists$ 的表示，代表<u>存在</u>
  - `==` 是 *TLA+* 中对 $\triangleq$ 的表示，代表<u>等价于</u>
  - 因此 `Divides(p, n) == \E q \in Int : n = p * q` 代表<u>方法 `Divides(p, n)` 等价于，存在一个属于整数的数 $q$，使得 $p\times q = n$ </u>，如果满足以上条件，那么就说明 $p$ 是 $n$ 的因子
- 第四行：终止线
- 第五、六行：被注释，写明程序修改历史和作者，有 *Toolbox* 自动更新

<br/>

#### 用 *TLC* 执行一下
以上我们已经通过 *TLA+* 定义了一个最为基础的方法，然后就可以通过 *TLC* 验证一下了。在 *Toolbox -> TLC Model Checker -> New Model...* 中新建 *TLC Model*，新增表达式 `Divides(2,4)`，然后执行。

![](http://nutslog.qiniudn.com/17-11-26/25803310.jpg?imageView2/0/w/540)

Oops，报错了。
```
The `Evaluate Constant Expression? section?s evaluation failed.
TLC encountered a non-enumerable quantifier bound Int.
line 10, col 27 to line 10, col 29 of module EuclidAlgorithm
```
这是因为定义的 $q \in Int$，而 Integers 是一个无穷集合，*TLC* 在验证时，会遍历集合，因此会报以上错误。
可以，将 $\exists q \in Int$ 改为 $\exists q \in 1...n$

<br/>

#### 更多表达式
`Divides(p,n)` 定义了判断 $p$ 是否为 $n$ 的因子。要求得最大公约数，还需要更多的表达式
```TLA+
DivisorsOf(n) == { p \in n : Divides(p, n) }
SetMax(S) == CHOOSE i \in S : \A j \in S : i >= j
```
等价于

![](http://nutslog.qiniudn.com/17-11-26/38864427.jpg)

其中 `DivisorOf(n)` 表示 $n$ 的所有因子，例如`DivisorsOf(493)` 等价于集合 {1, 17, 29, 493}
$CHOOSE\quad x \in S:P(x)$ 表示从集合 $S$ 中选取一元素 $x$，使得 $P(x)$ 为 true。例如$Foo \triangleq CHOOSE \quad i \in Int : i^2 = 4$，其中的 $Foo$ 等于 -2 或者 2。
`SetMax(S) == CHOOSE i \in S : \A j \in S : i >= j` 表示表达式 `SetMax(S)` 入参为集合 S，从集合 S 中任选一个元素 i，使得所有属于集合 S 的元素 j，都比 i 小，即 i 为所有元素的最大值。

最后，加入表达式 `GCD(m, n)`，先求得 m, n 的所有的因子，并求交集，最后在交集中找出最大值，这便是我们需要的最大公约数！
```TLA+
GCD(m, n) == SetMax(DivisorsOf(m) \cap DivisorsOf(n))
```

完整代码如下
```TLA+
---------------------------------- MODULE GCD ----------------------------------
EXTENDS Integers

Divides(p, n) == \E q \in 1..n : n = p * q
DivisorsOf(n) == { p \in 1..n : Divides(p, n) }
SetMax(S) == CHOOSE i \in S : \A j \in S : i >= j
GCD(m, n) == SetMax(DivisorsOf(m) \cap DivisorsOf(n))
================================================================================
\* Modification History
\* Last modified Sun Nov 26 14:24:28 CST 2017 by wangwc
```

![](http://nutslog.qiniudn.com/17-11-26/52355900.jpg)

#### *TLC* 验证
在 *TLC* 中配置表达式 `GCD(20, 30)`,执行 *TLC*，返回 10

![](http://nutslog.qiniudn.com/17-11-26/48817546.jpg)

### 以 *PlusCal* 简化欧几里得算法
在定义中，已经介绍了 *PlusCal*语言是 *TLA+* 的更适用于 C/C++, Java 工程师的一种语言。可以通过类似 Java 的语法编写程序，然后由系统自动转化为 *TLA+*，更为友好，效率也更高。

#### *PlusCal* 实现
```+Cal
---------------------------- MODULE EuclidAlgorithm ----------------------------
EXTENDS Integers
CONSTANT M, N

ASSUME /\ M \in Nat \{0} 
       /\ N \in Nat \{0}

(*
--algorithm ComputeGCD
{   variable x = M, y = N;
    {   while( x # y ) 
        { if (x < y) { y := y - x}
            else { x := x - y }}}}
*)

\* BEGIN TRANSLATION
\* END TRANSLATION

================================================================================
\* Modification History
\* Last modified Sun Nov 26 15:22:36 CST 2017 by wangwc
\* Created Sat Oct 14 15:40:30 CST 2017 by wangwc
```
#### 代码解读
- 第三行：定义了两个常量，M, N。需要在 *TLC* 程序执行前赋值。
- 第五-六行：规定了 M, N 属于自然数集(不包含 0)
- 第 8-14 行：为 *PlusCal*代码，`(* *)` 为 *TLA+* 注释代码块，*TLA+*程序执行时，会忽略，但若被定义为 *PlusCal* 后除外。该段代码于第9行以 `--algorithm`定义了这段注释为 *PlusCal* 代码。*PlusCal* 实现的是辗转相减法，与欧几里得算法不完全一致。
- 第 16-17 行：指明了 *PlusCal* 翻译为 *TLA+* 代码都插入的位置。

<br/>

#### 通过 *Toolbox* 翻译 *PlusCal*
在 *Toolbox* 中，点击 *File->Translate PlusCal Algorithm*，会生成如下：

```
---------------------------- MODULE EuclidAlgorithm ----------------------------
EXTENDS Integers
CONSTANT M, N

ASSUME /\ M \in Nat \{0} 
       /\ N \in Nat \{0}

(*
--algorithm ComputeGCD
{   variable x = M, y = N;
    {   while( x # y ) 
        { if (x < y) { y := y - x}
            else { x := x - y }}}}
*)

\* BEGIN TRANSLATION
VARIABLES x, y, pc

vars == << x, y, pc >>

Init == (* Global variables *)
        /\ x = M
        /\ y = N
        /\ pc = "Lbl_1"

Lbl_1 == /\ pc = "Lbl_1"
         /\ IF x # y
               THEN /\ IF x < y
                          THEN /\ y' = y - x
                               /\ x' = x
                          ELSE /\ x' = x - y
                               /\ y' = y
                    /\ pc' = "Lbl_1"
               ELSE /\ pc' = "Done"
                    /\ UNCHANGED << x, y >>

Next == Lbl_1
           \/ (* Disjunct to prevent deadlock on termination *)
              (pc = "Done" /\ UNCHANGED vars)

Spec == Init /\ [][Next]_vars

Termination == <>(pc = "Done")

\* END TRANSLATION

================================================================================
\* Modification History
\* Last modified Sun Nov 26 16:41:36 CST 2017 by wangwc
\* Created Sat Oct 14 15:40:30 CST 2017 by wangwc
```

![](http://nutslog.qiniudn.com/17-11-26/75450839.jpg)

顺利获得翻译后的 *TLA+* 代码。此处不再对 *TLA+* 语法展开解释了，具体可以参考以下书目
- *Principles and Specifications of Concurrent Systems*，Leslie Lamport，2015
- *Specifying Systems, The TLA+ Language and Tools for Hardware and Software Engineers*, Leslie Lamport, 2002
- *The PlusCal Algorithm Language*, Leslie Lamport, 2009

相关资料都可以在 Lamport 个人主页上获得 http://lamport.azurewebsites.net/tla/tla.html

<br/>

### *TLC* 的原理
最后，介绍一下 *TLA+* 的核心功能，*TLC Model Checker* 的原理见下图：

![](http://nutslog.qiniudn.com/17-11-26/44607114.jpg)

*TLC* 维护着两个数据结构
- 一个用来保存所有已知状态的集合 seen, 上图红绿点
- 一个 FIFO 队列 queue 用来维护还被检验的未达的状态，左图蓝色点

若数据结构过大，TLC 将利用硬盘空间存储，因此可以溯及的状态将非常多。

校验每个 next-state，按以下步骤：
- 验证新的状态是否已存在于集合 seen
  - 若不存在，则验证其是否满足恒定量 (Invariant)检验
    - 若满足恒定量检验，则将这个状态加入集合 seen
      - 若该状态存在 next state，则将其加入队列 queue 尾端
      - 若不存在 next state，则记为 End
    - 若不满足恒定量验证， 则报错
  - 若存在，则跳过

*TLC* 的终止状态为所有集合 seen 中状态都被 检验，queue 不存在状态待检验；且所有被检验的状态都满足恒定量条件。所存在状态不满足恒定量条件，也不存在 next state，则报错。

<br/>

# 工业界的应用
在了解 *TLA+* 过程中，也了解到诸多大厂都已经有了对 *TLA+* 的应用，诸如 *Microsoft，Amazon*。引用一篇 *Amazon* 工程师发表的论文，来看看工业界对 *TLA+* 的应用。

> 以下实例数据与结论引用自 *How Amazon Web Services Uses Formal Methods*, BY CHRIS NEWCOMBE, TIM RATH, FAN ZHANG, BOGDAN MUNTEANU,MARC BROOKER, AND MICHAEL DEARDEUFF, 2015

## Amazon 的应用
在 2016 年，亚马逊 *AWS* 推出了 *S3* 服务（Simple Storage Service），在之后的 6年里，*S3* 的存储对象增长至万亿级，并在之后的不到一年里，其存储又翻了一倍。*S3* 存储的对象以每秒 110万增长。面对如此迅猛增长的业务，系统的复杂度也越来越大，因此 *Amazon* 尝试使用 *Formal Spec* 完成系统设计和校验。

他们选择了 *TLA+*
截止 2015年， *Amazon* 有数十个大型的复杂的系统，7 个团队使用着 *TLA+*，并且在 *Amazon* 内部鼓励使用 *TLA+* 作为系统设计和开发校验的例行步骤。

| System                            | Components                               | Line  Count | Benefit                                  |
| :-------------------------------- | :--------------------------------------- | :---------- | :--------------------------------------- |
| S3                                | Fault-tolerant, low level network  algorithm | 804 +Cal    | Found 2 bugs, then others in  proposed optimizations |
|                                   | Backgound redistribution of data         | 645 +Cal    | Found one bug, then another in  the first proposed fix |
| DynamoDB                          | Replication and group-membership  system | 939 TLA+    | Found 3 bugs requiring traces of  up to 35 steps. |
| EBS                               | Volume management                        | 102 +Cal    | Found 3 bugs                             |
| Internal distributed lock manager | Lock-free data structure                 | 233 +Cal    | Improved confidence though failed  to find a liveness  bug, as liveness  not checked |
|                                   | Fault-torlerant  replication-and-reconfiguration algorithm | 318 TLA+    | Found 1 bug and verified an  aggressive optimization |

**结论**
- *Formal Spec* 是 *Amazon* 已知的可以用来发现其他系统无法发现的系统设计错误的方法
- *Formal Spec* 十分适用于现在的主流软件开发，并且回报丰厚
- *Amazon* 已将 *Formal Spec* 作为例行步骤用于设计开发复杂的系统，例如公有云

<br/>

# 有何启发
*Formal Spec* 的历史由来已久，但为何在近些年来的顶级论文和论坛上才焕发新生？

1. 软件工程的不断发展。科学家们曾经认为 formal spec 是最好的保证软件质量的手段，但随着软件工程领域的不断发展，设计模式、框架的使用、配置化管理等方法的使用，大大减少了软件开发的错误，并极大提升了效率。Formal Spec. 似乎并不是不可或缺的了
2. 市场瞬息万变。互联网的大发展，带来对软件服务迅速迭代响应的要求，用户相比较软件的错误，更期待软件和服务的快速更新。Formal Spec. 这种存在于 waterfall 开发模式的方法，有点跟不上时代了
3. Formal Spec. 使用范围有限。针对 Critical System，例如航天、操作系统、交通系统。现阶段更适用于基础架构，如云服务，数据库服务，并发集群等，但对用户交互、响应无能为力。
4. 可扩展性不好。无法随集群的扩展和功能的增加而扩展
5. 其它，诸如搞计算机的数学不好，哈哈。Leslie Lamport 在其主页显要位置吐槽了这点，[*Why Don't Computer Scientists Learn Math?* Leslie Lamport, 28 March 2017](http://lamport.azurewebsites.net/tla/math-knowledge.html)

Wikipedia 上，罗列了几十种 *Formal Spec Lang*，在技术选择上，*Amazon* 的论文中指出：在技术选型过程中，最先发现并使用了 *TLA+*，认为其已经能够满足需求，而并未更多*Formal Spec Lang*进行比较和选择。因此 *TLA+* 是否为最合适最好用的 Spec Lang，并未可知。

<br />

# 总结
*TLA+* 并不是多么难的一个概念，对于软件开发是否选择使用 *TLA+*，这还得有需求来决定。当前对于云平台的搭建，对系统有高可用、高并发等需求的系统，是比较适合 *TLA+* 的，但日常的 Spring 框架开发，CRUD 代码编写，则没有必要使用了。

<br />

# 参考资料
[1] Formal Specification 词条，Wikipedia,  https://en.wikipedia.org/wiki/Formal_specification
[2] *Who's Sitting on Your Nest Egg?*, Davis, Robin S. https://www.amazon.com/Whos-Sitting-Your-Nest-Egg/dp/1933538805
[3] Duck Typing, Wikipedia, https://zh.wikipedia.org/wiki/%E9%B8%AD%E5%AD%90%E7%B1%BB%E5%9E%8B#cite_note-1
[4] Leslie Lamport 个人主页 http://www.lamport.org/
[5] *How Amazon Web Services Uses Formal Methods*, By Chris Newcombe, Tim Rath, Fan Zhang, Bogdan Munteanu,marc Brooker, And Michael Deardeuff, 2015
[6] *Principles and Specifications of Concurrent Systems*，Leslie Lamport，2015
[7] *Specifying Systems, The TLA+ Language and Tools for Hardware and Software Engineers*, Leslie Lamport, 2002
[8] *The PlusCal Algorithm Language*, Leslie Lamport, 2009
[9] *Specifying Concurrent Systems with TLA+*, Leslie Lamport, 23 April 1999
[10] *Euclid Writes an Algorithm:A Fairytale*, Leslie Lamport, Microsoft Research Illustrated by Steve D. K. Richards, 6 June 2011
[11] Learn TLA+ Website,  https://www.learntla.com/introduction/
[12] *Model Checking TLA+ Specifications*, Yuan Yu1, Panagiotis Manolios2, and Leslie Lamport
[13] *The Wildfire Challenge Problem*, Leslie Lamport, Madhu Sharma, Mark Tuttle, and Yuan Yu, 4 Jan 2001

