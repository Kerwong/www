---
title: '聊聊 Formal Specification, 举个验证并发的例子'
date: 2017-11-26 19:34:38
tags:
- TLA+
- Formal Specification
---

在 17 年 11月 20日那篇文章中，拉开了 *TLA+* 的序幕。终于从无到有，了解了 *TLA+* 的面貌。

但对于 *TLA+* 真正的威力，前一篇文章，并没有感性的认识。在学习的过程中，找到了一个网上比较好的例子，可以 帮助对 *TLA+* 有更深入的理解，例子摘自 [Learn TLA+ 网站](https://www.learntla.com/introduction/)。

<br/>

在交易系统中，转账是最为常见的业务需求。

设想有这样一个普遍场景，甲的账户有 10元，乙账户有 10元，此时甲将 5元转至乙账户，那么甲账户金额变为 5元，乙账户金额变为 15元，转账完成。

但是，事情往往并没有我们所想象的那么简单。


<!--more-->

# 单线程下转账 
## 理想场景，v1.0

根据前面描述的场景，可以写出 *PlusCal* 代码如下：

```tla
----------------------------- MODULE BankTransfer -----------------------------
EXTENDS Naturals, TLC
(* 
--algorithm transfer
variables alice_account = 10, 
          bob_account = 10, 
          money = 5;
begin
A: alice_account := alice_account - money;
B: bob_account := bob_account + money;
C: assert alice_account >= 0
end algorithm 
*)

\* BEGIN TRANSLATION
\* END TRANSLATION
================================================================================
\* Modification History
\* Last modified Sun Nov 26 19:55:33 CST 2017 by wangwc
\* Created Sat Oct 14 18:59:32 CST 2017 by wangwc
```

![](http://img.wenchao.wang/17-11-26/22388669.jpg?imageView2/0/w/440)

以上代码首先定义了三个变量，`alice_account = 10, bob_account = 10, money = 5`

然后开始转账：

- A. Alice 账户扣除 5元
- B. Bob 账户增加 5元
- C. 判断 Alice 账户当前金额是否大于 0，显然如果账户金额小于 5元，是无法满足转账操作的。


此场景有两个问题，一是转账金额并非会固定为 5元，假设我们将转账范围扩大到 1~20元；二是不应该仅在账户金额扣除后断言账户金额大于等于 0，在转账前就该判断。因此需对以上代码改进。

<br />


## 转账 v1.1

```tla
EXTENDS Naturals, TLC
(*
--algorithm transfer
variables alice_account = 10, bob_account = 10, money \in 1..20;

begin Transfer:
    if alice_account >= money then
        A: alice_account := alice_account - money;
        B: bob_account := bob_account + money;
    end if;
C: assert alice_account >= 0
end algorithm 
*)

\* BEGIN TRANSLATION
\* END TRANSLATION

MoneyNotNegative == money >= 0
```

此版本代码，首先新增了 `if-else` 判断账户初始金额是否大于转账金额，其次将 money 改为 1..20 范围，最后，新增了恒定量表达式 `MoneyNotNegative == money >= 0`

<br />

## 转账 v1.2
上述场景基本满足了一般的情况，但如果遇到以下异常情况呢？

假设 Alice 去转账给 Bob，系统检测到她账户内金额满足转账金额，然后从 Alice 账户中扣款 1000 元。但此时，服务器崩了！那么 Bob 将无法收到 Alice 的转账，Alice 的 1000 元从系统中消失了！

为了避免此类问题，在代码中加入对资金总额的检验，要求在转账前后资金总额保持不变。定义变量 `account_total`和恒定量 `MoneyInvariant == alice_account + bob_account = account_total`

```tla
EXTENDS Naturals, TLC
(* 
--algorithm transfer
variables alice_account = 10, bob_account = 10, money \in 1..20;
          account_total = alice_account + bob_account;
          
begin Transfer:
    if alice_account >= money then
        A: alice_account := alice_account - money;
        B: bob_account := bob_account + money;
    end if;
C: assert alice_account >= 0
end algorithm *)

\* BEGIN TRANSLATION
\* END TRANSLATION

MoneyNotNegative == money >= 0
MoneyInvariant == alice_account + bob_account = account_total
```

<br />

## *TLC* 验证

实现了以上设计后，可以用 *TLC Model Checker*检查一下设计是否有问题了。

1. 新建一个 Model，设置 Temporal Formula 为 Spec (`Spec == Init /\ [][Next]_vars`，为 *Toolbox* 翻译 *PlusCal* 代码为 *TLA+* 时自动添加)
2. 勾选 Deadlock
3. 新增两个恒定量判断，`MoneyNotNegative, MoneyInvariant`

![](http://img.wenchao.wang/17-11-26/88522190.jpg?imageView2/0/w/500)

执行 *TLC*，结果如下：

![](http://img.wenchao.wang/17-11-26/87726795.jpg)

*TLC* 报错，错误信息是违反了恒定量 MoneyInvariant。
具体是指，当执行到 B 步骤时，`alice_account = 9，bob_account = 10`，而初始时的资金总额 
```tla
account_total = 20
alice_account + bob_account = 19
```
违反了 MoneyInvariant 中两者必须时刻相等的规定，因此报错。

<br />

## 转账 v2.0
转账 v1.2 中的错误，在日常实践中是非常常见的，解决方案也是现成的，便是将转账已事务（Transaction）的方式实现。
在 *PlusCal* 中定义事务，是将步骤前的标签统一。

因此，对 v1.2 代码加入事务，得到以下 v2.0 代码：
```PlusCal
(* --algorithm transfer
variables alice_account = 10, bob_account = 10, money \in 1..20;
          account_total = alice_account + bob_account;
          
begin Transfer:
    if alice_account >= money then
        A: alice_account := alice_account - money;
           bob_account := bob_account + money;
    end if;
C: assert alice_account >= 0
end algorithm *)
```
只改了 *PlusCal* 代码部分，其余不变。将原本的步骤 A, B 合为了步骤 A，即告诉 TLA+ 这两步需视为一个原子操作，不可拆分。

<br />

# 并发 v1.0
以上的转账操作，都是在单个线程下发生的。在实际操作中，还可能遇到多线程的情况，那么如何用 *TLA+* 去实现并校验多线程下程序的准确性呢？

```PlusCal
(* --algorithm transfer
variables alice_account = 10, bob_account = 10;
          account_total = alice_account + bob_account;

process Transfer \in 1..3
    variable money \in 1..20;
    
begin Transfer:
    if alice_account >= money then
        A: alice_account := alice_account - money;
           bob_account := bob_account + money;
    end if;
C: assert alice_account >= 0
end process
end algorithm *)
```
有多线程下的代码实现如上，首先新增了 `process Transfer \in 1..3` 表明设置了 3个线程，命名为 Transfer。然后将 money 这一全局变量改为了线程内的局部变量。

<br />

## *TLC*校验
为了使得错误更为明显，删除了 *TLC Model Check* 中对恒定量 `MoneyNotNegative` 的校验。

执行 *TLC* 后得

![](http://img.wenchao.wang/17-11-26/24442384.jpg)

可以看出，代码在执行时违反了断言 C，出现了 alice_account 金额小于 0 的情况。
具体出现在第一线程执行到 Transfer， money = 1，第二线程执行到 C， money = 1，第三线程执行到 C，money = 10。此时全局变量 alice_account = -1， bob_account = 21.

之后我尝试了多种设计，都无法避免在多线程下出现 bug。因此一种较好的设计就是对转账操作加锁，保证只有一个线程处理。

<br />

# 总结
经过以上介绍，对 *TLA+* 与 *PlusCal* 有了更进一步的了解，也在实践中对 *Formal Spec* 有了更深的理解。

1. *TLA+* 可以帮助开发者发现尚未意识到的问题， 能对现有的设计做完备的检验。例如 *TLA+* 可以通过执行中报错，告诉开发者在步骤中加入事务，虽然所举的例子已经是事务课程的经典中的经典，但对于更多的情况下，我们对于事务的使用与否是不确定的，*TLA+* 可以更好的帮助我们。
2. *TLA+* 可以发现问题，但并不提供解决方案。例如在并发的例子中，*TLA+* 告诉我们多线程下执行转账操作可能会遇到错误，但并不会告知开发者如何解决。在框架中加入事务，还是在数据库上加锁？这些都必须是由开发者自己提出。


<br />

# 参考资料
[1] A Example from Learn TLA+ Website, https://www.learntla.com/introduction/example/