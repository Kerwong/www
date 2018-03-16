---
title: '关于 Java 8 的后知后觉之总结'
date: 2017-09-21 19:20:24
tags: 
- Java
- Reading
---

还记得在上一份工作面试时，被问到了是否熟练 `Java8`和`Scala`, 我说不会。

Java 8 本已是一项不新的技术，虽然不复杂，却没掌握，的确是我不该。入职新东家后，纯正的互联网基因给了我短时间掌握和使用的机会。在学习了 《Java 8 in Action》，并经过一段时间实践后，在此做一次后知后觉的总结。



Java 8 于 2014年 3月发布，主要的新特性我认为就是两个：流处理、函数式编程。

**函数式编程**是一个古老而久远的话题。一句话总结，就是函数被作为一等公民，方法可以直接传递函数，函数只有输入输出，而不对外界造成影响（无共享的可变数据）。例如方法 `getBetterApple(Apple A, Apple B, Comparator<Apple> comp)` 中的 `Comparator<Apple>` 就是一个函数，此处定义了一个方法实现获得一个更好的苹果，但具体什么是“好”的这个评判标准，则可以通过传入函数来改变，例如按照大小、颜色、水分等等来比较。为了适应函数式编程，Java 8 对原有的接口做了相应改变，允许了在 `interface` 中定义 `default` **默认方法**。

而**流处理**，是针对日常工程中最为常见的集合制造与处理过程，其基础是函数式编程。Java8 提供了过滤、映射、循环等常用操作的 Stream API，并支持开发者自定义实现。并在流基础上，提供了**多线程**封装，只需要将 `stream()` 改为 `parallelStream()` 就完成了从单线程向多线程的转变，非常简单，不过其中也有些细节（坑），下文会展开介绍。

除了以上两点，Java 8 还提供了 `Optional` 、异步 API、新的时间处理API 等。



<!--more-->



# 函数式编程

在工程中，最常见的操作便是对 Collection 集合数据进行一系列的处理，例如有一筐苹果 `List<Apple>`，一般的操作可能会有过滤掉大小过小、颜色过青的苹果，然后按照质量逆序排列，然后按照产地进行分组等等，而其中过滤规则、排序规则、分组规则等等，都可能随着业务发展而发生变化，因此需要对这些进行**行为参数化**。

例如以下例子，`filterApple()` 就可以接受一个参数化的行为，

```java
public static List<Apple> filterApple(List<Apple> inventory, ApplePredicate p) {
  List<Apple> result = new ArrayList<>();
  for (Apple apple : inventory) {
    if (p.test(apple)) {
      result.add(apple);
    }
  }
  return result;
}
```

行为

```java
public class AppleGreenPredicate implements ApplePredicate {
    @Override
    public boolean test(Apple t) {
        return t.getColor().equalsIgnoreCase("Green");
    }
}
```

调用

```java
Filter.filterApple(main.inventory, new AppleGreenPredicate());
```

对于以上代码，还是太麻烦了，仅仅一个判断，还需要新建个接口！于是提出了**Lambda表达式或者称为匿名函数**，以简化以上代码。

不在需要 `AppleGreenPredicate` 了，调用改为

Lambda 表达式

```java
Filter.filterApple(main.inventory, (Apple a) -> "green".equals(a.getColor()));
```



## Lambda 表达式

```java
(Apple a) -> "green".equals(a.getColor())
```

Lambda 表达式是匿名函数，有完整函数结构：

- 入参参数列表， `Apple a`
- 函数主体， `"green".equals(a.getColor())`
- 返回类型，即为 `equal()` 的返回

有两种写法

```java
([parameters]) -> expression	// 参数列表或有，简单实现
([parameters]) -> { statements; }	// 一般用于比较复杂的实现
```



## 函数式接口

函数传递，依赖于**函数式接口**，例如前文的 `ApplePredicate` 便是一个函数式接口。

- 函数式接口，只能定义一个抽象方法，若有其他的方法，需要是**默认方法**
- 函数式接口可加注解 `@FunctionalInterface`（非必选），加了注解后 IDE 会检查抽象方法是否唯一，建议加上
- 函数式接口中，抽象方法名无关紧要，**函数描述符**才是关键，如 `(Apple a) -> "green".equals(a.getColor())` 的描述符为 `(Apple a) -> boolean`，函数描述符是函数式接口的签名。



 Java 8 提供了一些泛型函数式接口，实践来看，是足够一般的操作使用了，常用的有以下：

| 函数式接口          | 函数描述符        | 语义                                       |
| -------------- | ------------ | ---------------------------------------- |
| Predicate<T>   | T -> boolean | 布尔表达式，判断 T 真假的操作                         |
| Consumer<T>    | T -> void    | 消费一个对象，例如打印 T 的结果                        |
| Function<T, R> | T -> R       | 从对象 T 中抽取换转为出对象 R，例如传入 String, 返回其 length() |
| Supplier<T>    | () -> T      | 创建一个对象，例如返回 new Apple()                  |



一般使用泛型函数式接口，泛型只接受对象引用，因此会对原始类型进行**装箱(boxing)/拆箱(unboxing)**操作，这是有成本的，因此可以使用一些原始类型特化的函数式接口，例如 `IntPredicate, ToDoubleFunction `等。



## 函数的注意事项

1. 函数不允许引用保存在栈上的局部变量！例如 `this`，或者以下代码

   ```java
   int port = 1337;
   Runnable r = () -> System.out.println(port);
   port = 8080;
   ```

   都是不被允许的。函数内的变量必须是隐式最终的。如果要引用以上的 `port`，那么必须显式声明为 `final int port`。这样的设计是为了之后的并行化，使得调用函数不依赖线程。

   函数式编程不鼓励命令式编程模型，函数应减少对外界变量产生影响，但函数内可引用在堆上的变量，例如实现 `(Apple a) -> list.add(a+1)` 之类的操作。

2. 函数的复合，很多函数式接口提供了常用的复合方法，例如 `Comparator`，以 `java.util.function.Predicate` 为例，除了函数式接口 `boolean test(T t)` 以外，还有 `and, or, negate, isEqual` 等默认方法

   ```java
   @FunctionalInterface
   public interface Predicate<T> {
       boolean test(T t);

       default Predicate<T> and(Predicate<? super T> other) {
           Objects.requireNonNull(other);
           return (t) -> test(t) && other.test(t);
       }

       default Predicate<T> negate() {
           return (t) -> !test(t);
       }

       default Predicate<T> or(Predicate<? super T> other) {
           Objects.requireNonNull(other);
           return (t) -> test(t) || other.test(t);
       }

       static <T> Predicate<T> isEqual(Object targetRef) {
           return (null == targetRef)
                   ? Objects::isNull
                   : object -> targetRef.equals(object);
       }
   }
   ```

   这些默认方法会返回同类型的值，因此允许进行链式编程，例如

   ```java
   Predicate<Apple> greenApple = (Apple a) -> "green".equals(a.getColor());
   Predicate<Apple> greenAndHeavyOrRedApple =
   	greenApple.and((a -> a.getWeight() > 150)).or(a -> "red".equals(a.getColor()));
   ```

   ​

# 流处理

`Stream`流 是 Java 8 所引入的另一个重要的 Java API，**流允许以声明性方式处理数据集合，是从支持数据处理操作的源生成的元素序列**

一段标准的流处理，例如

```java
List<Dish> menu = new ArrayList<>();
List<String> names = menu.stream()              //←─从菜单获得流
        .filter(d -> d.getCalories() > 300)     //←─中间操作，过滤出卡路里大于 300
        .map(Dish::getName)                     //←─中间操作，映射，获取每道菜的名称
        .limit(3)                               //←─中间操作，选择前三
        .collect(Collectors.toList());          //←─终端操作，将Stream转换为List，返回
```

以上代码逻辑和实现都非常清晰，流处理好处之一，就是将原来的 `for-each` 转换为了内部迭代，而减少了诸多中间变量的定义。



![](http://nutslog.qiniudn.com/18-1-7/51713297.jpg)

> 上图摘自《Java in Action》4.2 流简介



- 流相比较与集合，更侧重于计算，而非数据。流中元素按需计算，就像一个延迟创建的集合。
- 流的数据是有序的
- 流中元素，只遍历一遍
- 一些流操作本身会返回一个流，因此可以多个流链式编程，因此可以优化，例如**延迟和短路**



## 使用流

流的使用，包括三件事：

- 一个**数据源**（如集合）来执行一个查询
- 一个**中间操作链**，形成流水线，类似构建器模式
- 一个**终端操作**，执行流水线，返回非流的结果

| 操作                          | 类型         | 返回类型        | 函数式接口                  | 函数描述符          | 描述                                       |
| --------------------------- | ---------- | ----------- | ---------------------- | -------------- | ---------------------------------------- |
| filter                      | 中间         | Stream<T>   | Predicate<T>           | T -> boolean   | 过滤元素，符合添加返回 true，否则 false                |
| distinct                    | 中间（有状态-无界） | Stream<T>   |                        |                | 元素去重                                     |
| skip                        | 中间（有状态-有界） | Stream<T>   |                        |                | 略去前 n 个元素                                |
| limit                       | 中间（有状态-有界） | Stream<T>   | long                   |                | 截断流，取流中 n 个元素                            |
| map                         | 中间         | Stream<R>   | Function<T,R>          | T -> R         | 映射，将元素 T 流转为 R 流                         |
| flatMap                     | 中间         | Stream<R>   | Function<T, Stream<R>> | T -> Stream<R> | 流扁平化，一般是将数组元素流转为一个流，例如 Stream<String[]> 转为 Stream<String> |
| sorted                      | 中间（有状态-无界） | Stream<T>   | Comparator<T>          | (T, T) -> int  | 对流元素排序                                   |
| *Match (anyMatch/noneMatch) | 终端         | boolean     | Predicate<T>           | T -> boolean   | 判断流元素是否有符合的元素                            |
| find* (findAny/findFirst)   | 终端         | Optional<T> |                        |                | 查询并返回满足条件的流元素                            |
| forEach                     | 终端         | void        | Consumer<T>            | T -> void      | 遍历整个流，例如打印所有流元素                          |
| collect                     | 终端         | R           | Collector<T, A, R>     |                | 将流转化为集合                                  |
| reduce                      | 终端         | Optional<T> | BinaryOperator<T>      | (T, T) -> T    | 归约，例如将元素合并                               |
| count                       | 终端         | long        |                        |                | 计数，返回流中元素个数                              |



## 归约



# 并行处理

parallelSream

Fork/Join 框架



# 组合式异步编程



# 进阶实践







# 参考资料

[1] *《Java 8 in Action（Lambdas, streams, and functional-style programming）》*Raoul-Gabriel Urma, Mario Fusco, Alan Mycroft 著，陆明刚，劳佳译，人民邮电出版社 2016 年 4月第 1版

