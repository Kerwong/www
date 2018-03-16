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

![](http://nutslog.qiniudn.com/18-3-13/33943255.jpg)

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

### 包/权限管理

1. 包导入优先查找 Go 的安装目录，然后才按顺序查找 GOPATH 变量列出的目录
2. 标识符（包括函数，变量的标识符）的首字母的大小写控制是否从包中公开。**首字母大写，公开；小写，不公开**。

```

```

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

## 接口 interface/多态

Go 本身并不是一门 OO 的语言，但还是支持了部分 OO 的理念，例如多态。如果了解 C++ 的虚表和 Java 的 OO 概念，对 Go 的多态理解会有所帮助，但 Go 的多态和 C++、Java 有所区别的。最主要的一点区别就是数据和方法的分离。

如果用户定义的类型实现了某个接口 `interface` 类型声明的一组方法，那么用户定义的类型的值就可以赋值给这个接口，这个过程本身是多态的。

> Go中的任何对象都可以表示为 `interface{}`

```go
//----------------- 包 test ----------------------
// 定义的类型
type User struct {
	Name string
	Age  int
}

// 定义的接口
type Describe interface {
	GetName() string	// 对包外可见
	getAge() int	// 对包外不可见
}

// 接收者类型为指针的实现
func (u *User) getAge() int {
	return u.Age
}
func (u *User) GetName() string {
	return u.Name
}

//----------------- 包 main ----------------------
func test1(d test.Describe) {
	fmt.Println(d.GetName())
	//fmt.Println(d.getAge()) 调用不了 getAge
}

func main() {
	u := test.User{"Alice", 30}
	test1(&u)
}
```



## 并发

### goroutine

goroutine 是一个独立于其他函数运行的函数，与线程有所区别，一个线程可运行多个 goroutine

go func() {} (matcher, feed)

### channel



# 深入 Go 语言

## 内存模型



### 垃圾回收



## 网络问题







<br/>

# 附录

## Go 的单元测试

Go 下有几种单测方法：

1. 基础测试 basic test，只使用一组参数和结果来测试一段代码
2. 表组测试 table test，多组参数和结果测试一段代码
3. 模仿 mock，模拟网络和数据库环境，进行测试

### 基础测试

Go 语言下的单元测试，严格准守这 **“约定大于配置”** 的规则，必须遵守约定，测试工具才会将其视为单元测试进行执行。

1. 文件名必须以 `_test.go` 结尾
2. 必须 `import "testing"`
3. 测试用例函数必须以 `Test` 作为开头
4. 测试用例函数入参必须为 `t *testing.T` ，并且无返回

```go
import "testing"

func TestHello(t *testing.T) {
	fmt.Println("Hello")
	t.Log("12")
}
```

> `t.Log` 系列为测试正常输出，若仅有 `t.Log` 输出，则表示测试通过
>
> `t.Error` 系列不会终止测试函数运行，但会在结果中显示为测试函数执行错误
>
> `t.Fatal` 系列会终止当前测试函数运行，进入下一个测试函数

<br/>

#### 表组测试

表组测试就用用一个切片存储一组输入参数，并通过迭代执行该切片所有输入。

以下代码摘自 《Go 语言圣经》，http://gopl-zh.b0.upaiyun.com/ch11/ch11-02.html

```go
import (
	"testing"
)

const checkMark = "\u2713"
const ballotX = "\u2717"

func TestEcho(t *testing.T) {
	var tests = []struct {
		newline bool
		sep     string
		args    []string
		want    string
	}{
		{true, "", []string{}, "\n"},
		{false, "", []string{}, ""},
		{true, "\t", []string{"one", "two", "three"}, "one\ttwo\tthree\n"},
		{true, ",", []string{"a", "b", "c"}, "a,b,c\n"},
		{false, ":", []string{"1", "2", "3"}, "1:2:3"},
	}

	t.Log("Start")
	{
		for _, test := range tests {
			t.Logf("echo(%v, %q, %q)", test.newline, test.sep, test.args)
			{
				out = new(bytes.Buffer) // captured output
				if err := echo(test.newline, test.sep, test.args); err != nil {
					t.Errorf("%s failed: %v", ballotX, err)
					continue
				}
				got := out.(*bytes.Buffer).String()
				if got != test.want {
					t.Errorf("%s = %q, want %q", ballotX, got, test.want)
				}
			}
		}
	}
}
```

### 基准测试

基准测试是测试性能的方法，可以识别某段代码的 CPU 或内存效率，或者辅助配置工作池数量，以提高吞吐。

基准测试与单元测试在使用上大同小异。

1. 文件名必须以 `_test.go` 结尾
2. 必须 `import "testing"`
3. 测试用例函数必须以 `Benchmark` 作为开头
4. 测试用例函数入参必须为 `t *testing.B` ，并且无返回


```go
package test

import (
	"testing"
	"strconv"
)

func BenchmarkFormat(b *testing.B) {
	number := int64(10)

	b.ResetTimer()
	b.N = 5001

	for i := 0; i < b.N; i++ {
		strconv.FormatInt(number, 10)
	}
}

func BenchmarkItoa(b *testing.B) {
	number := 10

	b.ResetTimer()
	b.N = 5002

	for i := 0; i < b.N; i++ {
		strconv.Itoa(number)
	}
}
```

输出，单位 ns/op 表示每条指令消耗的纳秒数，B/op 表示每条指令消耗的内存

```
5001	        33.8 ns/op	       2 B/op	       1 allocs/op
5001	        40.0 ns/op	       2 B/op	       1 allocs/op
5002	        44.0 ns/op	       2 B/op	       1 allocs/op
5002	        40.4 ns/op	       2 B/op	       1 allocs/op
PASS
```

> 配置参数 -test.benchtime 5s -test.benchmem -test.count 2 -test.parallel 4 -test.timeout 120s



- -test.benchtime 5s 测试至少跑 5s
- -test.benchmem 显示内存消耗
- -test.count 2 每个测试函数跑两遍
- -test.parallel 4 并发
- -test.timeout 120s 若超过 120s 则退出


<br/>




# 参考资料

[1] Go 语言的基本数据类型, https://www.cnblogs.com/fengbohello/p/5854108.html
[2] 《Go语言程序设计》（The Go Programming Language）
[3] 极客学院，http://wiki.jikexueyuan.com/project/the-way-to-go/
[4] http://blog.csdn.net/u013790019/article/details/45397287
[5] 《Go 语言圣经》，http://gopl-zh.b0.upaiyun.com/ch11/ch11-02.html
