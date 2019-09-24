---
title: 'Java 8 中的函数式编程与流之总结'
date: 2016-09-21 19:20:24
tags: 
- Java
- Reading
---

还记得在上一份工作面试时，被问到了是否熟练 `Java8`和`Scala`, 我说不会。

Java 8 本已是一项不新的技术，虽然不复杂，却没掌握，的确是我不该。入职新东家后，纯正的互联网基因给了我短时间掌握和使用的机会。在学习了 《Java 8 in Action》，并经过一段时间实践后，在此做一次后知后觉的总结。



Java 8 于 2014年 3月发布，主要的新特性我认为就是两个：流处理、函数式编程。

**函数式编程**是一个古老而久远的话题。一句话总结，就是函数被作为一等公民，方法可以直接传递函数，函数只有输入输出，而不对外界造成影响（无共享的可变数据）。例如方法 `getBetterApple(Apple A, Apple B, Comparator<Apple> comp)` 中的 `Comparator<Apple>` 就是一个函数，此处定义了一个方法实现获得一个更好的苹果，但具体什么是“好”的这个评判标准，则可以通过传入函数来改变，例如按照大小、颜色、水分等等来比较。为了适应函数式编程，Java 8 对原有的接口做了相应改变，允许了在 `interface` 中定义 `default` **默认方法**。

而**流**，是针对日常工程中最为常见的集合制造与处理过程，其基础是函数式编程。Java8 提供了过滤、映射、循环等常用操作的 Stream API，并支持开发者自定义实现。并在流基础上，提供了**多线程**封装，只需要将 `stream()` 改为 `parallelStream()` 就完成了从单线程向多线程的转变，非常简单，不过其中也有些细节（坑），下文会展开介绍。

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

<br/>

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

<br/>

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

<br/>

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

<br/>

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



![](http://img.wenchao.wang/18-1-7/51713297.jpg)

> 上图摘自《Java in Action》4.2 流简介



- 流相比较与集合，更侧重于计算，而非数据。流中元素按需计算，就像一个延迟创建的集合。
- 流的数据是有序的
- 流中元素，只遍历一遍
- 一些流操作本身会返回一个流，因此可以多个流链式编程，因此可以优化，例如**延迟和短路**


<br/>


## 使用流

流的使用，包括三件事：

- 一个**数据源**（如集合）来执行一个查询
- 一个**中间操作链**，形成流水线，类似构建器模式
- 一个**终端操作**，执行流水线，返回非流的结果



流 StreamApi 提供了诸如筛选、切片、映射、查找、匹配、归约几类操作，部分如下：

| 操作                          | 类型         | 返回类型        | 函数式接口                  | 函数描述符          | 描述                                       |
| --------------------------- | ---------- | ----------- | ---------------------- | -------------- | ---------------------------------------- |
| filter                      | 中间         | Stream<T>   | Predicate<T>           | T -> boolean   | 过滤元素，符合添加返回 true，否则 false                |
| distinct                    | 中间（有状态-无界） | Stream<T>   |                        |                | 元素去重                                     |
| skip                        | 中间（有状态-有界） | Stream<T>   |                        |                | 略去前 n 个元素                                |
| limit                       | 中间（有状态-有界） | Stream<T>   | long                   |                | 截断流，取流中前 n 个元素                           |
| map                         | 中间         | Stream<R>   | Function<T,R>          | T -> R         | 映射，将元素 T 流转为 R 流                         |
| flatMap                     | 中间         | Stream<R>   | Function<T, Stream<R>> | T -> Stream<R> | 流扁平化，一般是将数组元素流转为一个流，例如 Stream<String[]> 转为 Stream<String> |
| sorted                      | 中间（有状态-无界） | Stream<T>   | Comparator<T>          | (T, T) -> int  | 对流元素排序                                   |
| *Match (anyMatch/noneMatch) | 终端         | boolean     | Predicate<T>           | T -> boolean   | 判断流元素是否有符合的元素                            |
| find* (findAny/findFirst)   | 终端         | Optional<T> |                        |                | 查询并返回满足条件的流元素                            |
| forEach                     | 终端         | void        | Consumer<T>            | T -> void      | 遍历整个流，例如打印所有流元素                          |
| collect                     | 终端         | R           | Collector<T, A, R>     |                | 将流转化为集合                                  |
| reduce                      | 终端（有状态-有界） | Optional<T> | BinaryOperator<T>      | (T, T) -> T    | 归约，例如将元素合并                               |
| count                       | 终端         | long        |                        |                | 计数，返回流中元素个数                              |

<br/>

**流操作的无状态和有状态：**

1. 完全无状态：如 `map, filter` 等是无状态的，因为流中每个元素不存在相互依赖关系，可以自由的并行化
2. 部分无状态：`reduce, sum, max` 等需要状态累积结果，存在一定的依赖关系，但也可以并行化，例如 10个元素一组，分别求和，然后对结果再次求和，就可以得到流元素总和，max, min 同理。
3. 有状态依赖：`skip, limit, sort， distinct`  等操作，是有状态的，必须将此操作执行完毕，方可执行流操作链的下一步，在并行化方面存在瓶颈。

<br/>

### 映射

流所支持的 map 方法比较简单，就是将一类元素转为另一类元素。

值得一提的是流的扁平化。

有时在处理数据时，会得到诸如 `Stream<String[]>, Stream<Stream<T>>` 这类的情况。需要将其转换为 `Stream<String>, Stream<T>` 处理，可以使用 `flatMap`。

```java
List<String> words = Arrays.asList("hello", "world");
List<String> chars = words.stream().map(o -> o.split(""))
		.flatMap(Arrays::stream)
		.collect(Collectors.toList());
```

> `map` 与 `flatMap` 都可以改变流中的元素类型，其本质的区别在于，使用 `map` ，仅仅可以改变流中每个元素的类型，但不影响流本身的处理，如果流原长度为 10，`map` 后仍然为 10，流中元素还是按部就班的处理。
>
> 但 `flatMap` 会直接改变流的长度，将原来长度为 10 的流，变为 20。那么，流的处理方式就改变了。

<br/>

### 查找

StreamAPI 提供查找功能，`*Match, find*` 等。

有两点需要注意的，`find*` 返回的是 `Optional<T>` 类型结果，这是个容器类，避免在流处理中因 null 造成 bug。

还有一点，关于 `findFirst`, `findAny` 的区别，`finaAny` 更适用于并行化，如果不在乎是否取第一个元素，那么 `findAny` 效率会更高。

<br/>

### 归约

归约，在 Wikipedia 上的解释是将一类问题转为另一类同质化同复杂度的问题。在 Java8 中 reduce 更类似于聚合的概念。

`reduce` 用来在流处理中，求和、求积、比较大小等操作。

例如，以下是简单的求和：

```java
int sum = list1.stream().reduce(0, (a, b) -> a +b);
```

StreamAPI 提供三种 reduce 接口

```java
T reduce(T identity, BinaryOperator<T> accumulator);
Optional<T> reduce(BinaryOperator<T> accumulator);
<U> U reduce(U identity,
			BiFunction<U, ? super T, U> accumulator,
			BinaryOperator<U> combiner);
```

第 1，2 种的区别在于，若不提供初始值，则返回的是 `Optional`，因为不能判断是否有值。

接口中的 `BinaryOperator<T> accumulator` 作用是将两个元素结合产生一个新值，需满足: 结合律 associative law（即运算顺序不影响运算结果），互不干扰的 non-interfering，无状态 stateless（即不依赖外部状态）。

<br/>

## 其他相关操作

### 数值流

在前面介绍函数式时，介绍过一些原始类型特化的函数式接口，例如 `IntPredicate, ToDoubleFunction `等。流也存在原始类型流，如 `IntStream, DoubleStream, LongStream`，若仅需要一般数值操作不需要转为对象，原始类型的流处理会更高效一些，因为避免了 `box/unbox` 的成本。

同时，StreamAPI 提供了转换的方法，

- **对象流 -> 数值流**：`mapToInt` 将对象流转为 `IntStream`
- **数值流 -> 对象流**： `mapToObj, boxed` 将数值流转为对象流。

<br/>

### 构建流

构建流的方式有很多：

1. 在实践中比较常用的，是**将容器类，诸如 `List, Map, Set` 等转化为流**。在  Java8 中，`Collection` 接口实现了默认方法 `stream`。

   ```java
   default Stream<E> stream() {
   	return StreamSupport.stream(spliterator(), false);
   }
   ```

2. **由数组创建流**，`IntStream s = Arrays.stream(new int[] {1, 2, 3, 4});`

3. **采用静态方法创建流**

   ```java
   Stream<Integer> s1 = Stream.of(1, 2, 3, 4);
   Stream<Object> s2 = Stream.builder().add(1).add(2).build(); // 只能构建 Object
   Stream<Integer> s3 = Stream.empty();    // 空的流
   ```

4. **由 IO 创建流**

   文件 NIO API 提供很多静态方法返回一个流。

   ```java
   Long count = Files.lines(Paths.get("/etc/hosts"))
                   .parallel()
                   .map(o -> o.split("\\W"))
                   .flatMap(Arrays::stream)
                   .filter(o -> !o.isEmpty())
                   .count();
   ```

   `Files.lines` 方法返回文件的每一行字符串。

5. **函数生成流**

   由数值流的 `range` 或 `rangeClosed` 方法生成数值流

   ```java
   LongStream s1 = LongStream.range(0, 100);  // 0~99
   LongStream s2 = LongStream.rangeClosed(0, 100);	// 0~100
   ```


<br/>


### 函数创建无限流

以上的所有流均是有界有长度的，但也可以通过 StreamAPI 创建长度无限的流。

> 无限流可以无穷的计算下去，一般会用 limit() 加以限制。
>
> 不可对无限流进行排序或归约，必须先进行 limit 限制



1. `Stream.iterate` 迭代生成

   提供一个初始值，如 0，第二个入参是一元操作 Lambda 如 `n -> n + 1` ，迭代生成一个完整的流。`iterate` 不会修改原有值，而是每次生成一个新的元组，状态是纯粹不变的。

   以下是输出斐波那契数列：

   ```java
   Stream.iterate(0, n -> n * 2);  // 依次 *2 的流
   // 斐波那契数列
   Stream.iterate(new int[]{1, 2}, o -> new int[]{o[1], o[0]+o[1]})
   		.limit(20)
   		.forEach(o -> System.out.println (o[0] + " " + o[1]));
   ```

2. `Stream.generate` 

   `generate` 入参是一个 `Supplier<T>` 函数式接口，函数描述符是 ` () -> T` 。

   ```java
   Stream.generate(() -> 1).limit(10);	// 长度为10，元素均为 1 的流
   Stream.generate(Math::random).limit(10); // 长度为 10，元素围随机数的流
   ```

<br/>

# 流收集

在上一节**流处理**中，介绍了流的筛选、切片、映射、查找、匹配、归约操作。

在完成流处理后，需要收集处理后的结果。`reduce` 归约可以收集一个汇总后的结果，但有时我们希望获得如分区、分组这样更丰富的结果，因此会用到收集器 `collect`。`collect` 可以实现更高级的归约，此外还能实现了分组、分区等。



## 原生收集器 `Collector<T, A, R>`

Java 8 提供了预定义的收集器，由 `Collectors` 提供工厂方法，主要提供三大功能：

1. 将元素归约和汇总为一个值
2. 元素分组
3. 元素分区

以下将分别举例论述。

<br/>

### 归约、汇总

`collect` 的归约与汇总可以实现比 `reduce` 更多更丰富的功能，一般的用法如下：

```java
List<Integer> nums = Arrays.asList(1, 2, 3, 4, 5);

nums.stream().collect(Collectors.counting());	// 计数
nums.stream().collect(Collectors.averagingInt(Integer::valueOf));	// 求平均

String s1 = str.stream().collect(Collectors.joining(", "));	// 字符串合并
```



Java 8 提供了 Collectors 静态工厂方法，返回 `Collector<T, A, R>`，归约、汇总相关的整理如下：

| 方法                             | 返回 R 的类型             | 作用                                       |
| ------------------------------ | -------------------- | ---------------------------------------- |
| toList                         | `List<T>`            | 将流中所有元素收集到 List                          |
| toSet                          | `Set<T>`             | 将流中所有元素收集到 Set，删除重复项                     |
| toCollection                   | `Collection<T>`      | 将流中所有元素收集到 指定的供应源创建的集合                   |
| counting                       | `Long`               | 计算流元素的个数                                 |
| summing*（summingInt 等）         | `T`                  | 对流中元素求和                                  |
| averaging*（averagingInt 等）     | `Double`             | 对流中元素求平均                                 |
| summarizing*（summarizingInt 等） | `*SummaryStatistics` | 对流中元素求统计，包括最大、最小、和、平均                    |
| joining                        | `String`             | 将流中元素合并成一个字符串                            |
| maxBy                          | `T`                  | 按比较器规则，返回流中最大元素，由 Optional 包裹            |
| minBy                          | `T`                  | 按比较器规则，返回流中最小元素，由 Optional 包裹            |
| reducing                       |                      | 从一个初始值开始，利用 BinaryOperator 与流中元素逐个结合，将流归约为一个值 |

<br/>

#### 收集 collect 与归约 reduce 的区别

在实践中，一开始我并不能很好的区分 `reduce` 和 `collect` 操作，因为二者都由“归约”操作，都是流中的终端操作。

例如，以下三组实现，在作用上完全一样，

```java
String s1 = str.stream().collect(Collectors.joining(", "));
String s2 = str.stream().reduce((a, b) -> a + ", " + b).get();

Long sum1 = nums.stream().collect(Collectors.reducing(0L, e -> 1L, Long::sum));
Long sum2 = nums.stream().map(e -> 1L).reduce(0L, Long::sum);

nums.stream().collect(Collectors.toList());
nums.stream().reduce(new ArrayList<>(), 
				   (List<Integer> l, Integer e) -> { l.add(e); return l; }, 
                	(List<Integer> l1, List<Integer> l2) -> { l1.addAll(l2); return l1; });
```

<br/>

那么二者到底有何区别呢？

1. 语义不同，`reduce` 语义旨在将两个值结合，生成一个新值，是不可变的归约，`collect` 的设计是改变容器，累计输出的结果。
2. 并行化，在前文提到过，`reduce`  的方法应该满足结合律 associative，互不干扰的 non-interfering，无状态 stateless 的要求，而上例中的 `List` 在并行时，被多个线程修改，是非线程安全的，同时线程对象的分配会影响性能。


<br/>


### 分组

分组是指根据一个或多个属性对集合进行分组。使用 `groupingBy`，根据元素的属性值对流中所有元素进行分组，并将该属性值作为结果 Map 的 Key，返回 `Map<K, List<T>>`

```java
// 一级分组
Map<ValueLevel, List<Transaction>> groupTransaction(List<Transaction> transactions) {
    return transactions.stream()
            .collect(groupingBy(Main::getTransactionValueType));
}

// 多级分组
Map<Integer, Map<ValueLevel, List<Transaction>>> groupMultiTransaction(List<Transaction> transactions) {
    return transactions.stream()
            .collect(groupingBy(Transaction::getYear, 
                    groupingBy(Main::getTransactionValueType)));
}

private static ValueLevel getTransactionValueType(Transaction t) {
    if (t.getValue() < 333) return ValueLevel.LOW;
    else if (t.getValue() < 666) return ValueLevel.MEDIUM;
    else return ValueLevel.HIGH;
}
```

按子组进一步归约，通过 `collectingAndThen` 包裹第三个 Collector `maxBy`，`maxBy` 归约后的结果会由 `Optional::get` 处理。

```java
// 由 collectingAndThen 包裹，对归约返回值进行处理
Map<Integer, Map<ValueLevel, Transaction>> groupMultiTransactionAndThen(List<Transaction> transactions) {
    return transactions.stream()
            .collect(groupingBy(Transaction::getYear, 
                            groupingBy(Main::getTransactionValueType, 
                                    collectingAndThen(maxBy(Comparator.comparingInt(Transaction::getValue)), 
                                            Optional::get)
                    )));
}

// 不由 collectingAndThen 包裹，不对归约返回值处理
Map<Integer, Map<ValueLevel, Optional<Transaction>>> groupMultiTransactionAndThen2(List<Transaction> transactions) {
    return transactions.stream()
            .collect(groupingBy(Transaction::getYear,
                    groupingBy(Main::getTransactionValueType,
                            maxBy(Comparator.comparingInt(Transaction::getValue)))
                    ));
}
```

<br/>

### 分区

分区是分组的特殊情况，仅进行布尔区分，由谓语判断是否。使用 `partitioningBy`, 对流中元素进行谓语判断来分区，并将该布尔结果作为结果 Map 的 Key，返回 `Map<Boolean, List<T>>`

```java
Map<Boolean, Map<ValueLevel, List<Transaction>>> partitionTransaction(List<Transaction> transactions) {
    return transactions.stream().collect(
            partitioningBy(t -> t.getYear() == 2012,	// 谓语
                    groupingBy(Main::getTransactionValueType)));	// 二级分组
}
```

<br/>

## 自定义收集器 Collector

Java 8 中提供了 `Collectors` 静态工厂方法来返回多种 `Collector` 接口实现。原生的 `Collector` 接口已经实现丰富的功能，一般实践中一般无需自定义收集器，但作为流中最重要的功能，还是简单介绍下。

`Collector` 接口源码如下：

```java
// T 是流中要收集的元素泛型
// A 是累加器类型，用于收集过程中累积部分结果的
// R 返回的对象类型
public interface Collector<T, A, R> {
	// 支持顺序归约
    Supplier<A> supplier(); // 建立一个新的结果容器
    BiConsumer<A, T> accumulator(); // 将元素添加至结果容器
    Function<A, R> finisher();  // 对结果容器最终转换
	// 支持并行归约
    BinaryOperator<A> combiner();   // 合并两个结果容器，用于支持并行归约
	// 行为定义
    Set<Characteristics> characteristics(); // 返回一个不可变的集合，定义收集器的行为

    enum Characteristics {
        UNORDERED,  // 归约不受流中元素遍历和累积顺序影响
        CONCURRENT, // 可多线程调用，可并行归约流。若未标记为 UNORDERED，则仅可用于无序数据源
        IDENTITY_FINISH // 表明 finisher 返回一个恒等函数，可跳过，表明 A 可不加检查的安全的转为 R
    }
}
```

![顺序归约，图片摘自 Java8 In Action](http://img.wenchao.wang/18-6-3/75270699.jpg)

![并行归约，摘自 Java8 In Action](http://img.wenchao.wang/18-6-3/30974481.jpg)

实现自定义的质数收集器

```java
// Integer 是流中要收集的元素泛型
// Map<Boolean, List<Integer>> 是累加器类型，用于收集过程中累积部分结果的
// Map<Boolean, List<Integer>> 返回的对象类型
public class PrimeCollector implements Collector<Integer,
                                                 Map<Boolean, List<Integer>>,
                                                 Map<Boolean, List<Integer>>> {
    @Override
    public Supplier<Map<Boolean, List<Integer>>> supplier() {
        return () -> new HashMap<Boolean, List<Integer>>() {
            {
                put(true, new ArrayList<>());   // 保存质数
                put(false, new ArrayList<>());  // 保存非质数
            }
        };
    }

    @Override
    public BiConsumer<Map<Boolean, List<Integer>>, Integer> accumulator() {
        return (Map<Boolean, List<Integer>> acc, Integer n) -> {
            acc.get(isPrime(acc.get(true), n)).add(n);  // 判断 n 是否为质数，并添加至相应 Map
        };
    }

    @Override
    public BinaryOperator<Map<Boolean, List<Integer>>> combiner() {
		// 该收集器不能并行使用, 以上写法正确, 然而并不会被调用，仅为了保持完整性，否则在检查 Collector 完整时会报错
        return (Map<Boolean, List<Integer>> m1, Map<Boolean, List<Integer>> m2) -> {
            m1.get(true).addAll(m2.get(true));  // 将质数集合合并
            m1.get(false).addAll(m2.get(false));    // 将非质数集合合并
            return m1;
        };
    }

    @Override
    public Function<Map<Boolean, List<Integer>>, Map<Boolean, List<Integer>>> finisher() {
        return Function.identity();
    }

    @Override
    public Set<Characteristics> characteristics() {
        return Collections.unmodifiableSet(EnumSet.of(Characteristics.IDENTITY_FINISH));
    }

    private static boolean isPrime(List<Integer> primes, int n) {
        int mid = (int) Math.sqrt(n);
        return takeWhile(primes, i -> i <= mid)
                .stream()
                .noneMatch(i -> n % i ==0);
    }
	
	// 只以质数作为除数
    private static <A> List<A> takeWhile(List<A> list, Predicate<A> p) {
        int i = 0;
        for (A item : list) {
            if (!p.test(item)) {
                return list.subList(0, i);
            }
            i++;
        }
        return list;
    }
}

```

验证性能

```java
public class PrimeMain {

    private static boolean isPrime(int n) {
        int mid = (int) Math.sqrt(n);
        return IntStream.rangeClosed(2, mid).noneMatch(t -> n % t == 0);
    }

  	// 原始方法
    private static Map<Boolean, List<Integer>> partitionPrimes(int n) {
        return IntStream.rangeClosed(2, n).boxed()
                .collect(Collectors.partitioningBy(c -> isPrime(c)));
    }

  	// 改良后的方法
    private static Map<Boolean, List<Integer>> partitionPrimesWithCustomCollector(int n) {
        return IntStream.rangeClosed(2, n).boxed().collect(new PrimeCollector());
    }

    public static void main(String[] args) {

        long fastest = Long.MAX_VALUE;
        for (int i = 0; i < 10; i++) {
            long start = System.nanoTime();
            partitionPrimesWithCustomCollector(1_000_000);  // min: 330ms, max: 1206ms
//            partitionPrimes(1_000_0000);                       // min: 12153ms, max: 17028ms
            long duration = (System.nanoTime() - start) / 1_000_000;
            System.out.println("execution done in " + duration + " ms");
            if (duration < fastest) fastest = duration;
        }
        System.out.println("Fastest execution done in " + fastest + " ms");
    }
}
```

可以看到，自定义的 Collector 接口实现效率远远高于简单的处理。

<br/><br/>

# 参考资料

[1] 《Java 8 in Action（Lambdas, streams, and functional-style programming）》 Raoul-Gabriel Urma, Mario Fusco, Alan Mycroft 著，陆明刚，劳佳译，人民邮电出版社 2016 年 4月第 1版
