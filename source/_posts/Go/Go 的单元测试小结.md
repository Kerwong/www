---
title: 'Go 的单元测试小结'
date: 2017-10-31 11:23:09
tags: 
- Go
- Reading
---

Go 下有几种单测方法：

1. 基础测试 basic test，只使用一组参数和结果来测试一段代码
2. 表组测试 table test，多组参数和结果测试一段代码
3. 模仿 mock，模拟网络和数据库环境，进行测试

<!-- more -->
<br/>

# 基础测试

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

## 表组测试

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

<br/>

# 基准测试

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

[1] 《Go语言程序设计》（The Go Programming Language）