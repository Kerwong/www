---
title: 'Java 数组总结'
comments: true
date: 2015-05-17 15:22:30
tags:
- Java
- Array
---

Java 语言中提供的数组是用来存储固定大小的同类型元素，在 JVM 内存结构中，是一块逻辑连续的内存。可以声明一个数组变量，如 numbers[100] 来代替直接声明100个独立变量number0，number1，....，number99。

![](http://nutslog.qiniudn.com/17-5-17/52198774-file_1495006008908_6eb6.jpg "数组")

数组的标识符其实只是一个引用，指向在堆中创建的一个真实对象，这个对象用以保存指向其他对象的引用。在上图中，为 myList  变量。
**[]  语法是访问数组对象的唯一方式**.

- 优点
  - 效率最高的存储和随机访问对象引用序列的方式，这是数组仅存的优点。
- 缺点
  - 数组对象大小固定，且在生命周期中不可改变

<!--more-->

# 数组使用
## 创建
```Java
int[] arr;    // 首选
int arr[];
```
<br/>

### 一维数组
```Java
int[] arr1 = {1,2,3,4,5,6,7,8,9,0};
int[] arr2 = new int[11];    // int[11] 这里的 11 必填，用于设置数组容量
// int[] arr3 = new int[-1]; # illegal, java.lang.NegativeArraySizeException
```

其他类型，包括所有基本类型、各种类都能作为数组指定的类型，但不包括泛型。
<br/>

### 多维数组
多维数组的声明和初始化与一维类似，写法略有不同。
```Java
int[][] arr1;            // 二维
char[][][] arr2;        // 三维
double[][][][] arr3;    // 四维
```

初始化多维数组需要注意，第一维必须给出长度，后面的维数，不可在前面维数为给定的情况下给出，即如果要给出第三维的长度，那么必须给出第一维和第二维的长度。
如果能理解数组标识符只是一个引用，那么就不难理解为何后几维长度可以不给出。
```Java
int[][] arr1;
arr1 = new int[10][];
arr1 = new int[4][6];
// arr1 = new int[][10];   # illegal
int[][] arr3 = {{1,2,3},{4,5,6}};
// arr1 = {{1,2,3},{4,5,6}};   # illegal

char[][][] arr2;
arr2 = new char[9][][];
// arr2 = new char[][9][]; # illegal
// arr2 = new char[][][9]; # illegal
// arr2 = new char[][3][4]; # illegal
arr2 = new char[1][2][];
// arr2 = new char[1][][3]; # illegal
```
<br/>

#### 粗糙数组
因为数组标识符只是一个引用，因此，在多维数组中，第二维及以上维度，长度可以不相等。例如
```java
int[][] arr1 = {
    {},
    {1,2,3},
    {4,5,6,7,8}
};

// Print: [[], [1, 2, 3], [4, 5, 6, 7, 8]]

Double[][][] arr2 = {
    {
        { 1.0, 1.2, 1.4},
        { 2.0, 2.2, 2.4, 2.6},
        { 3.1},
    },
    {},
    {
        {-1.0, -2.1, -3.2}
    },
};

// Print: [[[1.0, 1.2, 1.4], [2.0, 2.2, 2.4, 2.6], [3.1]], [], [[-1.0, -2.1, -3.2]]]
```
<br/>

### 复杂类型数组
数组可以存储复杂的类，例如 `Shape[] shapes = {new Circle(), new Triangle()};`
但数组与泛型结合并不好，不能实例化具有参数化类型的数组，例如
```java
//List<Integer>[] lists = new List<Integer>[10];  # illegal, 不能创建泛型数组

T[] arrT;  // 正确
//arrT = new T[10];   # illegal，不能创建泛型数组
```

擦除会移除参数类型信息，而数组必须知道持有的确切类型，以保证类型安全。
但，可以参数化数组本身类型
```java
public class Test {
    public static <T> void main(String[] args) {
        Integer[] integers = {1,2,3,4};
        Integer[] integers1 = new ClassParam<Integer>().f(integers);
        Integer[] integers2 = MethodParam.f(integers);
    }
}

class ClassParam<T> {
    public T[] f(T[] arg) { return arg; }
}

class MethodParam {
    public static  <T> T[] f(T[] arg) { return arg; }
}
```

注意，使用参数化而不使用参数化类的方便之处在于：不必为需要应用的每种不同类型都使用一个参数去实例化这个类，并且，可以将其定义为静态的。
<br/>

## 访问与处理
```java
int[] arr1 = {1,2,3,4,5,6,7,8,9,0};
// arr1[-1] = 10;   # illegal, java.lang.ArrayIndexOutOfBoundsException
// arr1[11] = 10;   # 同上
```

使用 foreach 遍历
```java
Double[][][] arr = {
    {
        { 1.0, 1.2, 1.4},
        { 2.0, 2.2, 2.4, 2.6},
        { 3.1},
    },
    {},
    {
        {-1.0, -2.1, -3.2}
    },
};

for (Double[][] a1 : arr) {
    for (Double[] a2 : a1) {
        for (Double a3 : a2) {
            System.out.println(a3 + "\t");
        }
    }
}
```
<br/>

# Arrays 类的使用
## asList()
`asList()`, 将数组转为 ArrayList  容器，而不是 LinkedList 。
注意，一维数组 `int[]`  将转为 size = 1  的 `List<int[]>` ，而不是 `List<int>` ，对于 `Double[][][]` ，则会存为 `List<Double[][]>` 。可见 asList  方法其实是将数组的标识符，即数组的引用存入了 List  容器。
```java
int[] arrI = {2,5,10,-1,3,0,5,99,7,-6,8};
Double[][][] arrD = {
    {
        { 1.0, 1.2, 1.4},
        { 2.0, 2.2, 2.4, 2.6},
        { 3.1},
    },
    {},
    {
        {-1.0, -2.1, -3.2}
    },
};

List<int[]> listI = Arrays.asList(arrI);  // listI size = 1
List<Double[][]> listD = Arrays.asList(arrD);  // listD size = 3
```
<br/>

## binarySearch()
`binarySearch()` ，二分查找，只支持一维数组。若查到，则返回其下标，若没查到，则返回 -1
注意，调用 `binarySearch()`  时，需要先执行 `sort()`  操作，否则将会返回一个 undefined  的值。

> Searches the specified array of ints for the specified value using the binary search algorithm. The array must be sorted (as by the {@link #sort(int[])} method) prior to making this call. If it is not sorted, the results are undefined. If the array contains multiple elements with the specified value, there is no guarantee which one will be found.
> —— JDK Arrays.java

```java
int[] arri = {2,5,10,-1,3,0,5,99,7,-6,8};

int r = Arrays.binarySearch(arri, -1);    // r = -1, undefined
r = Arrays.binarySearch(arri, 5);        // r = 6, undefined
r = Arrays.binarySearch(arri, 10);        // r = -12, undefined

Arrays.sort(arri);
int r = Arrays.binarySearch(arri, -1);    // r = 1
r = Arrays.binarySearch(arri, 5);        // r = 5
r = Arrays.binarySearch(arri, 10);        // r = 9
```
<br/>

## copyOf()
`copyOf()`  与 `copyOfRange()` ，将原数组拷贝至新数组，仅支持一维数组。若新数组比拷贝的数组长，填充 0，同样，拷贝时不可数组下标越界。
```java
int[] arri = {2,5,10,-1,3,0,5,99,7,-6,8};
int[] arr1 = Arrays.copyOf(arri,15);
int[] arr2 = Arrays.copyOf(arri,3);
int[] arr3 = Arrays.copyOfRange(arri, 2, 6);
// int[] arr4 = Arrays.copyOfRange(arri, 6, 2);    // java.lang.IllegalArgumentException: 6 > 2
```
<br/>

## equals()
`equals()` ，比较两个一维数组是否相等，若相等，返回 true ，否则 false
类似的，有 `deepEquals()` ，该方法针对 `Object[]`
<br/>

## fill()
`fill()` ，将数组内全部填充某一元素，常用于初始化，仅针对一维数组。
```java
int[] arr = new int[10];
Arrays.fill(arr, 88);
```
<br/>

## hashCode()
`hashCode()` , 根据给定的数组，计算其 hash 值 。仅支持一维数组。可以对两个数组分别求 `hashCode()` ，然后比较，若相等，则两个数组一致。
类似的，还有 `deepHashCode()` ，该方法针对 `Object[]`

> Returns a hash code based on the contents of the specified array. For any two non-null <tt>int</tt> arrays <tt>a</tt> and <tt>b</tt> such that <tt>Arrays.equals(a, b)</tt>, it is also the case that <tt>Arrays.hashCode(a) == Arrays.hashCode(b)</tt>.
> <p>The value returned by this method is the same value that would be obtained by invoking the {@link List#hashCode() <tt>hashCode</tt>} method on a {@link List} containing a sequence of {@link Integer} instances representing the elements of <tt>a</tt> in the same order. If <tt>a</tt> is <tt>null</tt>, this method returns 0.
> —— JDK Arrays.java

<br/>

## sort()
`sort()` , 对数组进行排序，默认为递增序。`sort()`  之后，**会改变原数组内元素的顺序！** 返回 void 。
此外，`sort()` 还允许指定范围，对范围内的元素进行排序。

<br/>

## toString()
`toString()` ，将数组转换成用于打印的字符串结构。类似的，还有 `deepToString()` , 针对的是 `Object[]` 。

<br/><br/>

# 参考资料
[1] Java 编程思想，Thinking in Java Fourth Edition，作者 Bruce Eckel，译 陈昊鹏
[2] Oracle The Java™ Tutorials, https://docs.oracle.com/javase/tutorial/java/nutsandbolts/arrays.html
[3]  Java 数组，菜鸟教程，http://www.runoob.com/java/java-array.html