---
title: Markdown 语法简单小结
comments: true
date: 2015-12-12 10:12:12
mathjax: true
tags:
- Markdown
---

最终，我的博客还是回归到了起点。
博客断断续续几年，尽是折腾界面美化和各种网站框架或者建站工具，最终，失去了其核心价值，即内容和思想的沉淀。这更使得我的博客流于表面，对于自己的成长，也没有起到太多正面的作用。

反思后，决心回归最简单的格式外观，将重点集中于高质量内容的沉淀上。
 这也是为什么又回到了 Markdown 的怀抱。

至于编辑器，我用过了众多纯编辑器，众多 Web 版的富文本编辑器，以及许许多多Markdown 编辑器后，决定使用最的 Vim。同时，也推荐一款 Markdown 编辑器`Typora`。这款软件足够轻量级，同时功能做到了尽可能的简单。至于 Web 编辑器，我使用`简书`。

<!—more-->


# Markdown 概述
> Markdown 是一种轻量级的 “标记语言”，创始人为约翰·格鲁伯（John Gruber）。它允许人们“使用易读易写的纯文本格式编写文档，然后转换成有效的XHTML(或者HTML)文档”。
> ——Wikipedia

Markdown 拥有这众多的优点
- 纯文本编辑
- 学习成本低
- 广泛的软件支持
- 在码农界有深厚的基础

<br/>

# 基础语法
## 强调
星号与下划线都可以，单是斜体，双是粗体，符号可跨行，符号可加空格

| 代码 | 效果 |
| ---- | ---- |
| `*这是斜体*` | *这是斜体* |
| `_这是斜体_` | _这是斜体_ |
| `**这是粗体**` | **这是粗体** |
| `__这是粗体__` | __这是粗体__ |

<br/>

## 标题
代码:
```
# 一级标题
## 二级标题
### 三级标题
#### 四级标题
##### 五级标题
###### 六级标题
```
效果如下：
> # 一级标题
> ## 二级标题
> ### 三级标题
> #### 四级标题
> ##### 五级标题
> ###### 六级标题


注意
1. 最后一个 `#` 字符与标题**中间要留有一个空格**
2. 标题共提供 **6** 级
3. 一般行文中，标题应置于行首。若置于表格中，可能无法正确解析 

<br/>

## 引用
Markdown 中引用通过符号 '>' 来实现。'>' 符号后的空格，可有可无。
在引用的区块内，允许换行存在，换行并不会终止引用的区块。如果要结束引用，需要一行空白行，来结束引用的区块。

代码：
```
> 这是一句引用
> 这句仍然在引用区块内
>> 这是一句嵌套引用
>> 这句仍然在嵌套引用区块内
>
> 另起一行的引用。前面需要一个视觉上的空行表示内层嵌套的结束，空行前面的('>')可以有可以没有。
```

效果如下：
> 这是一句引用
> 这句仍然在引用区块内
>> 这是一句嵌套引用
>> 这句仍然在嵌套引用区块内
>
> 另起一行的引用。前面需要一个视觉上的空行表示内层嵌套的结束，空行前面的**('>')**可以有可以没有。

<br/>

## 列表
### 有序列表
数字不能省略但可无序，点号之后的空格不能少。
虽然下面代码的序号是 1，2，4，但是在显示时，仍然为自然数序列，并不是完成与编号一致。
同样的，在列表的最后需要留有一行空行，以表达列表的结束，不然将作为一个无编号的列表存在。

代码：
```
1. 列表 A
2. 列表 B
4. 列表 C
```

效果如下：
1. 列表 A
2. 列表 B
4. 列表 C

<br/>
### 无序列表
符号之后的空格不能少，`-+*`效果一样，但不能混合使用

代码：
```
- 列表 A1
- 列表 B1

+ 列表 A2
+ 列表 B2

* 列表 A3
* 列表 B3
```

效果如下：
- 列表 A1
- 列表 B1

+ 列表 A2
+ 列表 B2

* 列表 A3
* 列表 B3

<br/>
### 嵌套列表
有序与无序，以及有序和无序列表本身都是可以自由的嵌套的。
Markdown 中的列表嵌套，通过**在符号前增加空格**来表示。同一级别下，前面的空格数目应该保持一致。每递进一级，我习惯上使用 2 个空格缩进来表示。

代码：
```
- 一级列表 A
- 一级列表 B
  - 二级列表 A
  * 二级列表 B
    + 三级列表 A
- 一级列表 C
```

效果如下：
- 一级列表 A
- 一级列表 B
  - 二级列表 A
  * 二级列表 B
    + 三级列表 A
- 一级列表 C

> 注意，有序列表的嵌套，也是通过预留空格实现

1. 有序一级列表 A
2. 有序一级列表 B
  1. 有序二级列表 A
  2. 有序二级列表 B
    - 无序三级列表 A
	- 无序三级列表 B
3. 有序一级列表 C

<br/>

## 分割线
三个或更多`-_*`，必须单独一行，可含空格。
例如以下形式，都可以表示为分割线。

代码：
```
---
- -    -
___
_   __
***
*  **
  *  *  *
```

<br/>

# 进阶语法
## 超链接
图片与链接，在 Markdown 语法中表达类似，都是 `[链接文字](链接地址)` 这样的形式。

### 普通链接
代码：
```
[Wikipedia Markdown 条目](https://zh.wikipedia.org/wiki/Markdown)
[Wikipedia Markdown 条目](https://zh.wikipedia.org/wiki/Markdown "Markdown 条目")
```

效果如下：
[Wikipedia Markdown 条目](https://zh.wikipedia.org/wiki/Markdown)
[Wikipedia Markdown 条目](https://zh.wikipedia.org/wiki/Markdown "Markdown 条目")

<br/>
### 图片链接
图片需要在 `[]` 前增加一个 `!` 以使得图片在网页上直接显示，而不仅仅是个链接形式。

代码:
```
![维基百科 Logo](https://zh.wikipedia.org/static/images/project-logos/zhwiki.png)
![维基百科 Logo](https://zh.wikipedia.org/static/images/project-logos/zhwiki.png "维基 Logo")
```
效果如下：
![维基百科 Logo](https://zh.wikipedia.org/static/images/project-logos/zhwiki.png)
![维基百科 Logo](https://zh.wikipedia.org/static/images/project-logos/zhwiki.png "维基 Logo")

上面分别有两个超链接和两张图片，两个超链接的区别在于一个增加了说明注释，而另一个没有，图片同理。

<br/>
### 索引链接
索引链接，本质上与前两种链接一致，只是索引链接将 `[链接文字](链接地址)` 分离为`[链接文字][索引]`, `[索引]:链接地址` 的形式。

代码：
```
[Wikipedia Markdown 条目][1]
[1]:https://zh.wikipedia.org/wiki/Markdown
```
效果如下：
[Wikipedia Markdown 条目][markdown]
[markdown]:https://zh.wikipedia.org/wiki/Markdown

<br/>

## 表格
对于表格的支持，要根据具体的 Markdown 解释器来判定。在 hexo 中，支持以下 Markdown 形式的表格。
需要注意以下几点：
1. 表格第一行为标题，样式会被特殊处理
2. `|` 前后要留有空格
3. 只要是三个 `-` 字符表示分隔线
4. 通过 `:` 来区分，左对齐、居中、右对齐

代码：
```
| 1 | 2 | 3 |
| --- |:---:| ---:|
| aaa | bbbbbb | c |
| aaaaaa | b | ccc |
```
效果如下：

| 1 | 2 | 3 |
| --- |:---:| ---:|
| aaa | bbbbbb | c |
| aaaaaa | b | ccc |

<br/>

## 代码
### 行内代码
如果要标记一小段行内代码，可以用反引号 **\`** 把它包起来

代码：
```
这是一段行内代码，`System.out.println("article id: " + articleId);` 摘自 Redis 工程。
```
效果如下：

这是一段行内代码，`System.out.println("article id: " + articleId);` 摘自 Redis 工程。

<br/>
### 区块代码
如果要成块的引用代码，有两种方法，一种是用制表符缩进，另一种，则是用三个反引号 **\`\`\`**，将代码块包起来。
在三个反引号后，加上语言说明，例如 **\`\`\`java** 这样，便指定了之后的代码采用 java 的高亮。

效果如下：
```java
public int genRandPost(int bound) {
	Random rand = new Random();
	int cnt = rand.nextInt(bound);				
	
	Map<String, String> map = new HashMap<String, String>();
							
	long articleId;
	for (int i = 0; i < cnt; i++) {
		articleId = jedis.incr("article:");
		map.put("author", "author" + i);
		map.put("article", "This is article " + i);
		jedis.hmset("article:" + articleId, map);
		map.clear();
	}
	System.out.println("Insert " + cnt + " posts.");
											
	return cnt;
}
```

<br/>

## 公式 
大神提供了 hexo 下自动部署 MathJax 插件。安装好插件后，遍可以使用 \\(LaTeX\\) 来显示数学公式了。
在行内输入公式，需要在公式前后加上两个反斜杠 '\' 以及一个括号，前后两个括号要成对。
而独立成行的公式，则使用两个美元符 '$'。

代码：
```latex
在行内插入公式 \\(x=\frac{-b\pm\sqrt{b^2-4ac}}{2a}\\) 是这样的。

$$x=\frac{-b\pm\sqrt{b^2-4ac}}{2a}$$

$$
\begin{eqnarray}
\nabla\cdot\vec{E} &=& \frac{\rho}{\epsilon_0} \\
\nabla\cdot\vec{B} &=& 0 \\
\nabla\times\vec{E} &=& -\frac{\partial B}{\partial t} \\
\nabla\times\vec{B} &=& \mu_0\left(\vec{J}+\epsilon_0\frac{\partial E}{\partial t} \right)
\end{eqnarray}
$$
```
效果如下：

在行内插入公式 \\(x=\frac{-b\pm\sqrt{b^2-4ac}}{2a}\\) 是这样的。

$$x=\frac{-b\pm\sqrt{b^2-4ac}}{2a}$$

$$
\begin{eqnarray}
\nabla\cdot\vec{E} &=& \frac{\rho}{\epsilon_0} \\
\nabla\cdot\vec{B} &=& 0 \\
\nabla\times\vec{E} &=& -\frac{\partial B}{\partial t} \\
\nabla\times\vec{B} &=& \mu_0\left(\vec{J}+\epsilon_0\frac{\partial E}{\partial t} \right)
\end{eqnarray}
$$

<br/><br/>

# 参考资料
[1] Wikipedia Markdown 条目，https://zh.wikipedia.org/wiki/Markdown
[2] 不如的博客，http://ibruce.info/2013/11/26/markdown/
[3] Markdown 语法说明 (简体中文版)，http://wowubuntu.com/markdown/index.html
[4] Markdown：让书写更美好，http://www.jianshu.com/p/17fdcf17bbb4
[5] Markdown中插入数学公式的方法, http://blog.csdn.net/xiahouzuoxin/article/details/26478179
