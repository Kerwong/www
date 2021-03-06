---
title: 'Go 语言学习汇总'
date: 2017-10-23 21:23:09
tags: 
- Go
- Reading
---

在区块链的研发过程中，无法避开对 `Go` 语言的学习，Go 对并发的支持是其最重要的特性之一，也是区块链这样的分布式系统所钟爱 Go 的原因之一。

Go 语言是一门**静态类型的，面向过程的非解释性的语言，其内置并发机制，自带垃圾回收器，编译与开发**速度都极快。

学习语言最快的方法，便是在应用中学习，并深入了解其底层的原理。通过对代码的学习以及对 《Go 语言实战》一书的学习，在此文中对 Go 作一些总结。

<!--more-->

# Go 语言入门

先来看一段典型的 Go 语言代码

```go
package main

import (
	"log"
	"os"
	"fmt"
	json "encoding/json"
	"search"
	_ "github.com/google/go-github/github"
)

const dataFile = "~/Workspace/Go/src/data/data.json"

type User struct {
	Name string `json:"name"`
	Type int32 `json:"type"`
}

func init() {
	log.SetOutput(os.Stdout)
}

func main() {
	fmt.Println("hello")
	getGroups.Run("world")
}
```

以上是一段典型的 Go 语言代码

1. `package main` 指定包名，同目录下的所有 `.go` 文件均需在同一包下。此外，程序的主入口 `main` 一定在 `package main` 下。
2. `import` 指定引入的包，可以是系统自带也可以是自己编写的，还可以是直接用于 URI 所指的远程的包。**Go 要求所有引用的包均被使用到，否则会报错**。如第 9 行，引用了 URI 指向的远程的包，但并未被使用，因此在前方加上 `_` 表示忽略（可以在任何地方表示丢弃某个值），这么做是因为需要引入包，并执行其 `init` 初始化方法，但代码中并不会立即使用该包，例如数据库包的驱动注册。
3. 第 12 行定义了一个字符串常量，可以看出 Go 并不需要手动指定变量类型
4. type 是定义了一个 `struct` ，`struct` 可以包含多种基础和复杂结构变量。其最后的 `json:"name"` 是指明了该 `struct` 序列化时 `json` 中的名称。
5. `init()` 方法先于 `main()` 方法执行
6. `main()` 是 Go 程序的主入口，一定在 `main` 包内。


<br />



## 基本知识

### 基本类型

Go 语言的基本类型同其他语言类似，有如下几种：

| 基本类型                            | 解释        | 备注                           |
| ------------------------------- | --------- | ---------------------------- |
| bool                            | 布尔        | true, false                  |
| int，int8，int16，int32，int64      | 有符号整型     | int 同 cpu 支持位数，为 32 位或 64 位  |
| uint，uint8，uint16，uint32，uint64 | 无符号整型     | uint 同 cpu 支持位数，为 32 位或 64 位 |
| uintptr                         | 无符号指针     | 存放一个指针，同 cpu 位数              |
| byte                            | 字节        | = uint8                      |
| **rune**                        | Unicode 码 | = int32，代表一个 Unicode 码       |
| float32，float64                 | 浮点型       | IEEE 754 标准                  |
| complex64， complex128           | 复数        |                              |
| string                          | 字符串       |                              |

<br/>



#### 数组 []

Go 中的数组，是长度固定的存储相同类型元素的一段连续内存。

一旦声明，数组的数据类型和长度就无法改变了，若要扩展，只能创建一个更大的数据，然后复制。

数组变量只是一个指向存储数组元素的内存的指针，这个同 C/C++ 是一致的。

```go
// 一维数组
// 仅声明一个长度为 5 的，元素为 int 的数组
var arr1 [5] int
// 声明一个长度为 5 的，元素为 int 的数组，并赋值
arr2 := [5] int{1, 2, 3, 4, 5}
// 声明一个长度由赋值元素决定的数组
arr3 := [...] int{6, 7, 8, 9}
// 指定 arr4[4] = 10, arr4 长度为 5
arr4 := [...] int{4: 10}
// 声明一个长度为 5，元素为 rune 的数组，并赋值索引 = 2 的值为 '你'，= 4 的值为 '好'
arr5 := [5] rune{2: '你', 4: '好'}
// arr3 长度不对，arr5 类型不对，指明长度的 [5] 不可缺
arr6 := [4] *[5]int{&arr1, &arr2, /*&arr3,*/ &arr4 /*, arr5*/ } 

// 多维数组
arr7 := [4][2]int{{1, 2}, {3, 4}, {5, 6}, {7, 8}}
```

<br/>



#### 切片 slice

切片是便于使用和管理的数据集合，是基于数组实现的。

底层也是数组的连续内存，但是可以自动扩展长度，Go 为切片增加了一些实用方法，如 `append` ，并且切片支持索引、迭代、垃圾回收。

```go
slice1 := []int{10, 30}        // 创建长度、容量为 2 的，元素初始为 10、30 的切片
slice2 := make([]string, 3, 5) // 创建长度为 3，容量为 5，元素为 string 的切片，长度需小于等于容量
slice3 := make([]int, 4)       // 创建长度、容量均为 4 的，元素为 int 的切片

// 三种创建空切片的方法
var slice4 []int
slice5 := make([]int, 0)
slice6 := []int{}

slice := []int{1, 2, 3, 4, 5}
// 基于切片创建切片
slice7 := slice[3:5]   // 长度为 2，容量为 2（slice 容量 5 - 前部舍去的 1，2，3）
slice8 := slice[2:3:4] // 长度为 3 - 2 = 1， 容量为 4 - 2 = 2
```

> 1. [] 为切片，[5] 为数组
> 2. 基于切片创建切片时，底层共享内存，因此 append(slice7, 50), 会改变 slice[4] 的值
> 3. 基于切片创建的切片，容量终止位置同原切片，除非限制了容量，如 slice8。当其 append 导致容量 > 2 后，将会复制到一块新的内存，而非改变原切片。

切片容量小于 1000 时，每次容量不足时会成倍增加容量。一旦超过 1000 个元素，则容量每次扩展 1.25 倍。

切片的头部会占用 3 个 uint 长度，分别存储底层数组指针、长度、容量。

![](http://img.wenchao.wang/18-3-13/33943255.jpg)

<br/>



#### 映射 map

映射是用于存储键值对的无序集合。

以关键字 `map` 定义一个映射。

```go
var m1 map[int][]string	// 定义一个为 nil 的 map
//Error: m1[1] = []string{"aaa", "bbb"}

m2 := make(map[int]string)
m2[123] = "Hello"

m3 := map[string][]string{"A": {"Alice, Alex"}, "B": {"Bob"}}
m3["C"] = []string{"Caroline"}

// 先判断是否存在，再使用
value, exists := m1[1]	// Go 语言支持多参数返回
if exists {
	fmt.Println(value)
}
```

<br/>



#### 指针和引用

Go 与 C++ 类似，用到了指针和引用。

```go
type Point struct {
	X int
	Y int
}

p1 := Point{1, 2}
p2 := Point{3, 4}
line := [2]Point{p1, p2}  // 值拷贝
line2 := [] *Point{&p1, &p2}	// 引用，底层数据共享
rect := [4] *[2]Point{&line, &line, &line, &line}
```

指针长度同 CPU 位数，此处不再赘述。

<br/>



#### 枚举 itoa

Go 语言本身没有提供枚举类型的关键字，但可以通过 `const + iota` 实现，如下

```go
const (
	Monday = iota	// value = 0
	Tuesday // value = 1
	Wednesday // value = 2
	Thusday
	Friday
	Saturday
	Sunday
)

week := Monday	// 使用
```

<br/>



### 分支判断

Go 语言中，`if-else` 判断有两种形式，一种是简单的逻辑条件判断，为 `true` 则进入分支；另一种是带初始化的 if，会在执行判断前，先执行初始化，这是一种简便用法，可以缩短代码长度。

```go
if err != nil {
  // do something
}

// 带初始化的 if
if _, exists := getResult(); exists {
  // do something
} else {
  // do another
}
```

此外，Go 语言支持 `switch` 关键字。同 if 一样，也可选带初始化。

```go
switch week {
case Monday:
	fmt.Println("星期一")
case Tuesday:
	fmt.Println("星期二")
case Wednesday: fallthrough
case Thusday: fallthrough
case Friday:
	fmt.Println("工作日")
default:
	fmt.Println("其他")
}
```

需要注意的是：

1. `switch` 结构，不在需要带有 `break`，所有分支默认自带
2. 如果在执行完每个分支的代码后，还希望继续执行后续分支的代码，可以使用  `fallthrough`  关键字来达到目的

<br/>



### 循环

Go 的循环通过 `for` 实现，也可以通过 `range` 关键字，实现 `for-each` 的效果

```go
for i := 0; i < 10; i++ {
  // do something
}

for index, value := range list {
  	fmt.Println(value)
}

// 无限循环
for {
  break;
}
```

Go 语言提供 `break`、`continue` 来控制循环执行。同其他语言一致。

Go 不支持 `while` 关键字

<br/>




### 函数

#### 基本调用

如下，入参 a,b,c, 类型分别为 int, int, string。返回类型为 int

```go
func sum(a, b int, c string) int {
	fmt.Println(c)
	return a + b
}
// 调用
total := sum( 1, 2, "hello")
```

#### defer 关键字

> 关键字 `defer` 允许我们推迟到函数返回之前（或任意位置执行 `return` 语句之后）一刻才执行某个语句或函数（为什么要在返回之后才执行这些语句？因为 `return` 语句同样可以包含一些操作，而不是单纯地返回某个值）
>
> —— 摘自极客学院，http://wiki.jikexueyuan.com/project/the-way-to-go/06.4.html

`defer` 一般被用来释放一些需要释放的资源。Go 这样的设计，可以缩短资源被初始化和被回收的代码间的距离，使得代码更清晰。

```go
func fun1() (n int, err error) {
	fmt.Println("func1 begin")
	defer fun2()
	return fmt.Println("func1 end")
}

func fun2() {
	fmt.Println("fun2")
}
```

调用 `fun1()`, 输出

```
func1 begin
func1 end
fun2
```

<br/>



#### 函数出入参/匿名函数/闭包/

以函数为入参

```go
func fun3(a int, f func(int, int, string) int) {
	f(a, 10, "world")
}

// 调用
fun3(5, sum)
```

> 注意，作为入参的函数 sum，必须要严格匹配 f 的**函数签名**，包括出入参个数和类型



以函数作为返回值，此处返回了函数签名为 `func(int, int, string) int` 的函数。

```go
func fun4(a int) func(int, int, string) int {
	return func(b int, c int, s string) int {
		fmt.Printf("%s, %d", s, a)
		return b * c
	}
}
// 调用
ff := fun4(30)
ff(40, 50, "foobar")	// 返回 2000
```

> 此处返回的匿名函数，就是**闭包**
>
> 闭包是一个结构体，记录了函数地址和引用环境变量的地址，可复用当前环境的变量。闭包对于函数式编程非常有用。

<br/>



### 包/权限管理

1. 包导入优先查找 Go 的安装目录，然后才按顺序查找 GOPATH 变量列出的目录

2. 标识符（包括函数，变量的标识符）的首字母的大小写控制是否对包外公开。**首字母大写，公开；小写，不公开**。

3. 短变量声明操作符 `:=` 有能力捕获引用的类型，可以创建一个未公开的类；但永远不能显示创建未公开的类

   ```go
   // --- package a ---
   type stu struct {
     name string
     age int
   }

   func NewStu() stu {
     return stu{name: "a", age: 20}
   }

   // --- package main ---
   func main() {
     v := a.NewStu()	// OK，v 的类型是 stu，虽然 stu 对包外不可见
     fmt.Println(v)
   }
   ```

4. 未公开的嵌入类型，若其声明标识符是公开的，则会向上暴露，外部类型可以直接访问这些公开标识符。嵌入类型会在下文介绍。

<br/>



### 一些困惑

1. `make` 和 `new` 新建变量

   `new` 和 `make` 均是用于分配内存：`new` 用于值类型和用户定义的类型，如自定义结构；**`make` 用于内置引用类型（切片、map 和管道）**。

   它们的用法就像是函数，但是将类型作为参数：`new(type)`、`make(type)`。

   `new(T)` 分配类型 T 的零值并返回其地址，也就是指向类型 T 的指针。它也可以被用于基本类型：`v := new(int)`。

   `make(T)` 返回类型 T 的初始化之后的值

   **new() 是一个函数，括号不可少**

2. `=` 与 `:=`

   `=` 是赋值， `:=` 是声明变量并赋值

   `:=` 只能在函数体内使用，可以自动判断类型

3. `nil`，空指针。等价于 C++ 和 Java 中的 NULL，是一些变量初始化的默认值，如指针、切片等

4. `var` , 用于声明变量，声明加赋值等价于 `:=`。 但由于 `:=` 只能用于函数内部，因此 `var` 会用来定义全局变量，作为对 `:=` 的补充

   ```go
   var a int = 10
   a := 10
   ```

<br/>



## 高级应用

### 接口 interface/多态

Go 本身并不是一门 OO 的语言，但还是支持了部分 OO 的理念，例如多态。

在 Go 语言中，对数据和方法进行了分离。在 `struct` 中定义数据类型和结构，在 `interface` 中定义方法的签名。

接口值是一个两个字长度的数据结构，一个字是包含一个指向内部表的指针，另一个是指向所存储值的指针。

如果用户定义的类型实现了某个接口 `interface` 类型声明的一组方法，那么用户定义的类型的值就可以赋值给这个接口，这个过程就是多态的。

> Go中的任何对象都可以表示为 `interface{}`, 其地位有点类似 Java 的 Object

如下所示，代码定义了 `type user struct` 和 `type manager interface`。 然后在 11 - 17 行中为 `user` 实现了接口 `manager` 的方法。在使用时，`interface` 可以接受实现了其所有方法的 `struct` 的指针。此时可以将该 `struct` 视为一个类的实例，该实例拥有了 `struct` 的数据，并实现了 `interface` 的方法。

如下第 32-41 行，都是先创建了 `struct` 的数据，然后将引用赋值给 `interface`。

```go
type user struct {
	name string
	age  int
}

type manager interface {
	getName() string
	setAge(int)
}

func (u *user) setAge(age int) {
	u.age = age
}

func (u *user) getName() string {
	return u.name
}

// 传入接口
func test(m manager) {
	m.getName()
	m.setAge(10)
}

// 传入结构
func test2(u user) {
	u.getName()
	u.setAge(20)
}

func TestMain(t *testing.T) {
	var a manager = &user{"a", 10}
	a.setAge(20)
	// test2(&a)	// Error, 因为 a 是 manager
  
	b := user{"b", 1}
	test(&b)
	test2(b) // 注意，不能是引用
  
    var c = user{"c", 3}	// 变量未定义为接口，但也可调用 user 实现的方法。
	c.setAge(20)
}
```

注意到 `func` 后声明的是 `(u *user)` ，这是指针接收器（pointer receiver），还有一种类型是 `(u user)` （values receiver）。这两者的区别在于:

1. ```go
   var v I = T{}  //对应 func(this T) test {}
   var v I = &T{} //对应 func(this *T) test {} 或 func(this T) test {}
   ```

2. **声明为`(this *T)` 即 pointer receiver 才可以修改 v 的值，声明为`(this T)` 即 value receiver 操作的是 v 的值拷贝，不会对 v 造成修改**


<br/>



### 嵌入类型

Go 支持将已有的 struct 直接嵌套入新的结构中，称之为嵌入类型。

通过嵌入类型，**内部结构的相关方法和变量等将提升至外部，作为外部类型的方法。也就是说，若内部类型实现了对某接口的实现，则外部类型也等于实现了该接口。**

外部类型可以声明与内部标识符相同的标识符，实现对内部的覆盖。

```go
type student struct {
	class int
	grade int
}

type EmbedPeople struct {
	student		// 嵌入类型，无变量名
	name string
}

type NonEmbedPeople struct {
	stu student
	name string
}

func (this *student) printSelf() {
	fmt.Println(this.class)
	fmt.Println(this.grade)
}

func TestMain(t *testing.T) {
	p := EmbedPeople{
		student: student{	// 采用嵌入类型默认名称
			class: 1,
			grade: 2,
		},
		name: "a",
	}
	p.printSelf()	// 嵌入类型，可直接使用
	p.student.printSelf()
  
    p1 := NonEmbedPeople{
		stu: student{
			class: 3,
			grade: 4,
		},
		name: "b",
	}
	// p1.printSelf()	invalid, 'case stu not an embed
	p1.stu.printSelf()
}
```

<br/>




### 并发

#### goroutine

并发编程非常重要，Go 语言以其对并发而闻名，其中最重要的机制便是 `goroutine`。

- Go 语言将每个 goroutine 视为独立的工作单元
- goroutine 相当于一个 Go 进程下的轻量级线程，被称为**协程**，调度由 Go 语言的逻辑处理器而非 OS 管理。
- goroutine 同步由`通信顺序进程（Communicating Sequential Process，CSP）`实现。CSP 是一种消息传递模型，而不是对数据加锁实现同步
- goroutine 维护一个队列，分配时间片给每个 goroutine。若阻塞时，将暂时从队列移出
- Go 语言默认使用机器 CPU 核数的逻辑处理器数
- Go 默认最多支持 1万个 goroutine，可通过参数 `SetMaxThreads` 修改。

```go
func TestGo(t *testing.T) {
	runtime.GOMAXPROCS(1)	// 设置最大逻辑处理器，此处设为 1

	var wg sync.WaitGroup	// 声明等候计数，此处设为 2
	wg.Add(2)	// 等候计数需要与以下的 goroutine 数相等，若太少，会有 goroutine 不会执行，若太多则会报 fatal error: all goroutines are asleep - deadlock!

	fmt.Println("Start Goroutines")

  	// 以下是 goroutine 的标准用法
	go func() {
		defer wg.Done()	// 当 goroutine 结束时，释放计数
		for count := 0; count < 100; count++ {
			fmt.Printf("A: %d\n", count)
		}
	}()

	go func() {
		defer wg.Done()
		for count := 0; count < 100; count++ {
			fmt.Printf("B: %d\n", count)
		}
	}()

	fmt.Println("Waiting for finish")
	wg.Wait()	// 等候计数全部释放

	fmt.Println("Gorountine End")
}
```

<br/>

#### 原子操作与互斥锁

锁是保证在并发时，数据同步的重要方式，类似于 Java，Go 提供了 `atomic` 原子操作包和 `sync` 互斥锁。

`atomic` 包下提供了 `AddXXX`, `LoadXXX`, `CompareAndSwapXXX`, `StoreXXX`, `SwapXXX`. 由名字就可知道作用，其中 `XXX` 代表基本数据类型。如下例，虽然 `Load` 和 `Add` 是分为两步，但每一步都是原子操作，因此最终结果无误

```go
package test

import (
	"testing"
	"runtime"
	"sync"
	"fmt"
	"sync/atomic"
	"time"
)

var wg sync.WaitGroup
var count int32		// 需共享的数据

func TestGo(t *testing.T) {
	runtime.GOMAXPROCS(1)
	wg.Add(2)
	fmt.Println("Start Goroutines")

	go addCounter("A")
	go addCounter("B")

	fmt.Println("Waiting for finish")
	wg.Wait()
	fmt.Println("Gorountine End")
}


func addCounter(name string) {
	defer wg.Done()

	for i := 0; i < 5; i++ {
		fmt.Printf("%s: old = %d\n", name, atomic.LoadInt32(&count))
		time.Sleep(100000)
		fmt.Printf("%s: new = %d\n", name, atomic.AddInt32(&count, 1))
		runtime.Gosched()	// 当前 goroutine 从线程退出，并放回到队列
	}
}
```

输出

```
Start Goroutines
Waiting for finish
B: old = 0
A: old = 0
A: new = 1
B: new = 2
A: old = 2
B: old = 2
... ...
A: old = 8
A: new = 9
B: new = 10
Gorountine End
```

当然 Go 也可以用互斥锁实现上述代码，只需要将 `addCounter` 少做改动

```go
var lock sync.Mutex	// 新增锁的声明

func addCounter(name string) {
	defer wg.Done()

	for i := 0; i < 5; i++ {
		lock.Lock()	// 上锁
		{
			count++
			runtime.Gosched()	// 从当前 goroutine 退出并放回队列
			fmt.Printf("%s: %d\n", name, count)
		}
		lock.Unlock()	// 释放锁
		time.Sleep(time.Duration(rand.Int63n(1000)))
	}
}
```



另一个互斥锁的例子，摘自 [Go 指南](https://tour.go-zh.org/concurrency/9) ， 对某一结构加入锁声明，可以实现对该结构的原子操作

```go
package main

import (
	"fmt"
	"sync"
	"time"
)

// SafeCounter 的并发使用是安全的。
type SafeCounter struct {
	v   map[string]int
	mux sync.Mutex
}

// Inc 增加给定 key 的计数器的值。
func (c *SafeCounter) Inc(key string) {
	c.mux.Lock()
	// Lock 之后同一时刻只有一个 goroutine 能访问 c.v
	c.v[key]++
	c.mux.Unlock()
}

// Value 返回给定 key 的计数器的当前值。
func (c *SafeCounter) Value(key string) int {
	c.mux.Lock()
	// Lock 之后同一时刻只有一个 goroutine 能访问 c.v
	defer c.mux.Unlock()
	return c.v[key]
}

func main() {
	c := SafeCounter{v: make(map[string]int)}
	for i := 0; i < 1000; i++ {
		go c.Inc("somekey")
	}

	time.Sleep(time.Second)
	fmt.Println(c.Value("somekey"))
}
```



`sync` 包下还提供了**读写锁 `RWMutex`**。读写锁是为了满足写不频繁但读比较频繁的资源的并发请求，读时不互斥，一旦有写入操作，才会上锁互斥。此处不再赘述，可以直接看 Go 的包源码。

<br/>



#### 通道 channel

锁自然可以实现并发操作的安全访问，但 Go 还提供了更强大的通道 `channel`, 通道的含义是，在两个 goroutine 之间搭建了一个通道，使得两个 goroutine 可以实现数据共享。

- 通道可以共享内置类型、命名类型、结构类型和引用的值或指针。
- 通道分为有缓冲 `buffered channel`和无缓冲通道`unbuffered channel`，无缓冲通道需发送和接收放 goroutine 都处于准备状态，不然将阻塞，有缓冲通道若缓冲超出容量，也将阻塞。
- 无缓冲通道可以保证同时交换数据

以下是有缓冲通道示例，摘自 《Go 语言实战》

```go
package test

import (
	"testing"
	"fmt"
	"sync"
	"strconv"
)

type Message string

var (
	num = 4	// goroutine 数量
	wg sync.WaitGroup
)

func TestChannel(t *testing.T) {
	wg.Add(num)

	c := make(chan Message, 2)	// 创建一个缓冲为 2 的通道

	for i := 0; i < num; i++ {
		go deal("No. "+strconv.Itoa(i), c)	// 循环创建 4 个 goroutine
	}

	for i := 0; i < 100; i++ {
		c <- Message("Task " + strconv.Itoa(i))	// 循环发起 100 笔工作，交由 4 个 goroutine 处理
	}

	close(c)	// 处理完所有工作时，关闭通道
	wg.Wait()	// 等待所有 goroutine 结束
}

func deal(name string, c chan Message) {
	defer wg.Done()
	for {
      	// 
		if msg, ok := <-c; ok {
          	 // 从通道取出工作，并完成
			fmt.Printf("I'm %s, do %s\n", name, msg)
		} else {
          	 // 意味着通道已清空，并被关闭
			fmt.Printf("I'm %s, Dead\n", name)
			return
		}
	}
}
```

> 在通道数据写入完毕后，需 close，否则 goroutine 永远 ok，永远不会执行到 return，会报 fatal error: all goroutines are asleep - deadlock!



# TBD

- 内存模型

- 垃圾回收
- 网络问题
- 机器底层实现机制 Mechanical Sympathy
- 面向数据的设计 Data Oriented Design
- 值和指针的语义 Value/Pointer Semantics
- 去耦/组合 Decoupling/Composition
- 错误处理 Error Handling
- 并发深入研究



这些主题，将于后期工作中逐步完善，2018年05月06日16:59:20

<br/>




# 参考资料

[1] Go 语言的基本数据类型, https://www.cnblogs.com/fengbohello/p/5854108.html
[2] 《Go语言程序设计》（The Go Programming Language）
[3] 极客学院，http://wiki.jikexueyuan.com/project/the-way-to-go/
[4] http://blog.csdn.net/u013790019/article/details/45397287
[5] 《Go 语言圣经》，http://gopl-zh.b0.upaiyun.com/ch11/ch11-02.html
[6] https://golang.org/doc/effective_go.htmlhttps://golang.org/doc/effective_go.html
[7] 《Go 语言实战》
