---
title: 'JDK 容器深入解析'
comments: true
date: 2015-05-17 10:10:13
tags:
- Java
- Collection
- JDK
---

![](http://img.wenchao.wang/17-5-17/20783500-file_1494988127341_466.jpg)

在 Java 编程中，常常需要一些数据结构用来保存我们所需要的数据。在 `C /CPP` 中，只提供数组和链表的实现，但诸如一些常用的稍复杂的数据结构，例如`Heap` 、`Stack` 、`Queue` 、`Hash` 表等，都需要自己编码实现，虽然灵活度很高，但在一些常用的结构上再浪费时间，就没有必要了。而 JDK ，则提供了一个不少实用的容器，供开发者使用，本文将详细解析一下 JDK 中提供的容器。

<!--more-->

# Java 容器类
Java 容器类库用途是“保存对象”，其中可以划为两个不同概念
1. **Collection** ：一个独立的元素的序列，这些元素服从一条或多条规则。其中又有：
  - List ：有序队列，必须按照插入的顺序保存元素
  - Set ：不能有重复元素
  - Queue ：按照队列规则，来确定对象产生的顺序
2. **Map** ：也被成为关联数组，用来保存一组成对的“键值对”对象，允许通过键来查找值。

![](http://img.wenchao.wang/17-5-17/63028248-file_1495001438479_156aa.png)
<br/>

## List
像 Array  一样， List  建立了数字索引与对象的关联。List 能自动扩容。
List 的接口实现有 ArrayList 、LinkedList ，它们都按照顺序保存元素。

- `ArrayList` ：数组实现，擅长于随机访问元素，但在中间插入和移除元素时比较慢。
- `LinkedList` ：双向链表实现，通过代价较低的 List 中间进行插入和删除操作，提供了优化的顺序访问。但在随机访问方面相对比较慢。LinkedList 还添加了可以使其用作 Stack 、Queue 或 Deque 的方法。
- `Vector` （不再使用）：矢量队列，和 ArrayList 一样，也是动态数组实现，区别在于 Vector  是线程安全的，而 ArrayList  不是。
- `Stack` （不再使用）：栈，继承自 Vector ，特点是“后进先出” （LIFO ），线程安全。和 LinkedList 一样，可以由 LinkedList 实现。

![](http://img.wenchao.wang/17-5-17/57392064-file_1494989548600_1776c.png)
<br/>

### 关于容量
#### 初始容量
ArrayList  采用的是**数组结构**，JDK  默认的初始容量是 10 
```Java
private static final int DEFAULT_CAPACITY = 10;
/**
* The array buffer into which the elements of the ArrayList are stored.
* The capacity of the ArrayList is the length of this array buffer. Any
* empty ArrayList with elementData == DEFAULTCAPACITY_EMPTY_ELEMENTDATA
* will be expanded to DEFAULT_CAPACITY when the first element is added.
*/
transient Object[] elementData;
```

而 LinkedList  采用的是**双向链表**结构，未设置初始容量。但有一个 Node  结构，用来存取数据。
```Java
transient int size = 0;
transient Node<E> first;
transient Node<E> last;

private static class Node<E> {
    E item;
    Node<E> next;
    Node<E> prev;

    Node(Node<E> prev, E element, Node<E> next) {
        this.item = element;
        this.next = next;
        this.prev = prev;
    }
}
```
<br/>

#### 容量的扩展
对于 ArrayList ，由于底层的数组实现，因此会存在数组容量不够的情况，此时变需要扩展。ArrayList  **一次扩容原容量的 1/2** ，例如原容量为 10，扩展后为 15。JDK  实现如下
```Java
private void grow(int minCapacity) {
    // overflow-conscious code
    int oldCapacity = elementData.length;
    int newCapacity = oldCapacity + (oldCapacity >> 1);
    if (newCapacity - minCapacity < 0)
        newCapacity = minCapacity;
    if (newCapacity - MAX_ARRAY_SIZE > 0)
        newCapacity = hugeCapacity(minCapacity);
    // minCapacity is usually close to size, so this is a win:
    elementData = Arrays.copyOf(elementData, newCapacity);
}
```
而 LinkedList  为链表操作，不存在分配的内存容量不足的情况。
<br/>

### 关于增删
在指定位置中插入或删除元素，LinkedList  要比 ArrayList  快很多，这是因为 ArrayList  会有一个数组元素移动的过程。
```Java
public void add(int index, E element) {
    rangeCheckForAdd(index);
    ensureCapacityInternal(size + 1);  // Increments modCount!!
    System.arraycopy(elementData, index, elementData, index + 1, size - index);
    elementData[index] = element;
    size++;
}
```

`ensureCapacity(size+1)`  的作用是 “确认ArrayList 的容量，若容量不够，则增加容量。”
真正耗时的操作是 `System.arraycopy(elementData, index, elementData, index + 1, size - index);`
Sun JDK 包的`java/lang/System.java` 中的`arraycopy()` 声明如下：
```Java
/**
* Copies an array from the specified source array, beginning at the
* specified position, to the specified position of the destination array.
* A subsequence of array components are copied from the source
* array referenced by <code>src</code> to the destination array
* referenced by <code>dest</code>. The number of components copied is
* equal to the <code>length</code> argument. The components at
* positions <code>srcPos</code> through
* <code>srcPos+length-1</code> in the source array are copied into
* positions <code>destPos</code> through
* <code>destPos+length-1</code>, respectively, of the destination
* array.*/
public static native void arraycopy(Object src,  int  srcPos, Object dest, int destPos, int length);
```

`arraycopy()` 是个JNI 函数，它是在JVM 中实现的。其作用是移动index  后所有的元素。而 LinkedList 不需要这一步的操作。因此在指定位置的增删，LinkedList  要比 ArrayList  快很多。
<br/>

### 关于查询
关于这两个容器的随机访问。LinkedList  要比 ArrayList  慢一些。
究其原因，是因为 ArrayList  可以通过index  直接获得元素（数组实现，归功于被分配了一块连续的内存），而 LinkedList  必须从头开始检索（各个 Node  之间并不处于连续的内存块中）。
虽然 LinkedList  比较慢，但在 JDK  中，仍然对此进行了优化：若index  < 双向链表长度的1/2 ，则从前向后查找; 否则，从后向前查找。
```Java
/**
 * Returns the (non-null) Node at the specified element index.
 */
Node<E> node(int index) {
    // assert isElementIndex(index);

    if (index < (size >> 1)) {
        Node<E> x = first;
        for (int i = 0; i < index; i++)
            x = x.next;
        return x;
    } else {
        Node<E> x = last;
        for (int i = size - 1; i > index; i--)
            x = x.prev;
        return x;
    }
}
```
<br/>

### 关于 Vector
<br/>

### 关于 Stack
<br/>

## Set
Set  容器用来保存**不重复的元素**，如果试图将相同的对象的多个实例添加到 Set  中，那么将会被阻止。通过对源码的分析，可以看出 Set 集合其实是对 Map  的封装，Map  存储的是键值对，那么我们将值隐藏，不向外界暴露，这样就形成了Set 集合。
Set  最常用的是测试归属性，即查询某个对象是否存在 Set  中，因此查找是 Set  中最重要的操作。
Set  具有与 Collection  完全一样的接口。Set  是基于对象的值来确定归属性的。

- `HashSet` ：无序，HashMap  实现，使用了 Hash  对查询进行了优化的 Set  实现，存入 HashSet  的对象必须定义 hashCode()。
- `LinkedHashSet` ：有序，使用链表维护元素的插入，同时使用了 Hash 来提高查询速度。
- `TreeSet` ：有序，使用红黑树维护数据的顺序。

![](http://img.wenchao.wang/17-5-17/76653471-file_1494990801304_17fe0.png)
<br/>

### 关于容量/数据结构
HashSet  底层通过 HashMap  实现 `private transient HashMap<E,Object> map;`。
在初始化时，默认大小为初始化时元素大小除以 3/4 的大小与 16 之间的较大者（与 HashMap  初始一致）。
例如初始化元素为 9，9/.75 = 12 < 16，则初始化大小为 16，若初始化元素为 30，30/.75 = 40 > 16，则初始化大小为 40。
其中除数 0.75 为默认，可以通过传入 loadFactor  修改，以分配更冗余或更紧凑的空间。
```Java
/**
* Constructs a new set containing the elements in the specified
* collection.  The <tt>HashMap</tt> is created with default load factor
* (0.75) and an initial capacity sufficient to contain the elements in
* the specified collection.
*
* @param c the collection whose elements are to be placed into this set
* @throws NullPointerException if the specified collection is null
*/
public HashSet(Collection<? extends E> c) {
    map = new HashMap<>(Math.max((int) (c.size()/.75f) + 1, 16));
    addAll(c);
}

/**
* Constructs a new, empty set; the backing <tt>HashMap</tt> instance has
* the specified initial capacity and the specified load factor.
*
* @param      initialCapacity   the initial capacity of the hash map
* @param      loadFactor        the load factor of the hash map
* @throws     IllegalArgumentException if the initial capacity is less
* than zero, or if the load factor is nonpositive
*/
public HashSet(int initialCapacity, float loadFactor) {
    map = new HashMap<>(initialCapacity, loadFactor);
}
```

   LinkedHashSet  继承自 HashSet ，因此底层也是通过 HashMap  实现，其在初始化时，会调用 HashSet  的初始化方法，但初始化的大小略有不同。
```Java
public LinkedHashSet(Collection<? extends E> c) {
    super(Math.max(2*c.size(), 11), .75f, true);
    addAll(c);
}
```

   TreeSet  的底层结构是红黑树，具体是通过 TreeMap  实现，这种结构帮助 TreeSet  保持元素的有序。
   在下图中可以看出，TreeSet  继承自 AbstractSet  并实现 NavigableSet  接口，而 NavigableSet  接口又继承自SortSet 。
   SortSet  继承自 Set  接口，主要声明 Set  中的元素以升序排列。因为需要排序，因此元素必须实现 comparator  方法。
>   All elements inserted into a sorted set must implement the Comparable interface (or be accepted by the specified comparator). Furthermore, all such elements must be mutually comparable: e1.compareTo(e2) (or comparator.compare(e1, e2)) must not throw a
>   ClassCastException for any elements e1 and e2 in the sorted set. Attempts to violate this restriction will cause the offending method or constructor invocation to throw a ClassCastException.
>   ——摘自 JDK SortSet.java

NavigableSet  继承自 SortSet ，在 SortSet  声明基础上，又新增了一些实用声明，具体参见 JDK  源码。需要注意的是，NavigableSet  允许将元素倒序排列，但如果倒序，效率会有所下降。
>   A {@code NavigableSet} may be accessed and traversed in either ascending or descending order.  The {@code descendingSet} method returns a view of the set with the senses of all relational and directional methods inverted. The performance of ascending operations and views is likely to be faster than that of descending ones.
>   ——摘自 JDK NavigableSet.java

TreeSet  作为 NavigableSet  的具体实现，底层的采用了 TreeMap  存储元素
```Java
/**
 * The backing map.
 */
private transient NavigableMap<E,Object> m;

// Dummy value to associate with an Object in the backing Map
private static final Object PRESENT = new Object();

/**
 * Constructs a set backed by the specified navigable map.
 */
TreeSet(NavigableMap<E,Object> m) {
    this.m = m;
}

public TreeSet() {
    this(new TreeMap<E,Object>());
}
```

关于 TreeMap  的初始化大小以及扩展，详情参照下文 Map  小节。
<br/>

### 关于增删
因为 Set  是对 Map  的封装，在 Set  中增加一个元素，就是在 Map 中增加一个 <K,V>  键值对，其中 Key  为插入 Set 的值，Value  固定为 PRESENT = new Object() ，PRESENT  为 static 。
```Java
public boolean add(E e) {
    return map.put(e, PRESENT)==null;
}
public boolean remove(Object o) {
    return map.remove(o)==PRESENT;
}
```
<br/>

### 关于查询
同 Map 下的查询
```Java
public boolean contains(Object o) {
    return map.containsKey(o);
}
```
<br/>

## Queue
Queue  队列，是一个典型的**先进先出 FIFO  容器**，即从容器的一端放入事物，从另一端取出，并且放入和取出的顺序是一致的。
队列常被用作可靠的将对象从程序的某一区域传输到另一区域的途径，在并发编程中特别重要。

- `LinkedList` ：LinkedList  实现了 Deque  接口，作为**双向链表结构**，LinkedList  能很好的实现 Queue  的先进先出操作。
- `ArrayDeque` ：通过**数组实现 Queue  的先进先出，作为 Queue  效率上优于 LinkedList ，作为 stack ，效率上优于 Stack （因为 Stack 底层会加锁）**，若要实现 Queue ，推荐优先使用 ArrayDeque ，而不是 LinkedList
- `PriorityQueue` ：优先队列，**数组结构，平衡二叉树实现**，不再是先进先出，而是赋予元素优先级，声明下一个弹出元素是最高优先级的元素。**不允许 null 元素存在**。

![](http://img.wenchao.wang/17-5-17/31468936-file_1495000986510_17260.png)
<br/>

### 关于容量
### LinkedList
LinkedList  采用双向链表实现，每次新增元素时，只需修改节点的引用即可将新元素插入，删除同理。因此不存在容量问题。
<br/>

#### ArrayDeque
ArrayDeque  采用数组实现，最小容量为 8，默认初始化大小为 16，ArrayDeque  要求其容量始终为 2 的幂次，即 16、32、64 等，由 `allocateElements` 方法实现。
```Java
public class ArrayDeque<E> extends AbstractCollection<E> implements Deque<E>, Cloneable, Serializable {
    transient Object[] elements; // non-private to simplify nested class access
    transient int head;  // 头索引
    transient int tail;  // 尾索引
    private static final int MIN_INITIAL_CAPACITY = 8;

    // ******  Array allocation and resizing utilities ******
    /**
     * Allocates empty array to hold the given number of elements.
     * 此方法将容量扩展至可容纳元素的最小的 2 的幂的大小，
     * 例如元素数量为 9，则扩展至 2^4 = 16，数量为 20，则扩展为 2^5 = 32，以此类推
     * @param numElements  the number of elements to hold
     */
    private void allocateElements(int numElements) {
        int initialCapacity = MIN_INITIAL_CAPACITY;
        // Find the best power of two to hold elements.
        // Tests "<=" because arrays aren't kept full.
        if (numElements >= initialCapacity) {
            initialCapacity = numElements;
            initialCapacity |= (initialCapacity >>>  1);
            initialCapacity |= (initialCapacity >>>  2);
            initialCapacity |= (initialCapacity >>>  4);
            initialCapacity |= (initialCapacity >>>  8);
            initialCapacity |= (initialCapacity >>> 16);
            initialCapacity++;

            if (initialCapacity < 0)   // Too many elements, must back off
                initialCapacity >>>= 1;// Good luck allocating 2 ^ 30 elements
        }
        elements = new Object[initialCapacity];
    }

    /**
     * Constructs an empty array deque with an initial capacity
     * sufficient to hold 16 elements.
     */
    public ArrayDeque() {
        elements = new Object[16];
    }

    /**
     * Constructs an empty array deque with an initial capacity
     * sufficient to hold the specified number of elements.
     * @param numElements  lower bound on initial capacity of the deque
     */
    public ArrayDeque(int numElements) {
        allocateElements(numElements);
    }
    …………
}
```

当 ArrayDeque  中**数组已满时，则将容量扩大一倍，容量始终保持 2 的倍数**，并将 head 和 tail 索引重置。
```Java
/**
 * Doubles the capacity of this deque.  Call only when full, i.e.,
 * when head and tail have wrapped around to become equal.
 */
private void doubleCapacity() {
    assert head == tail;
    int p = head;
    int n = elements.length;
    int r = n - p; // number of elements to the right of p
    int newCapacity = n << 1;
    if (newCapacity < 0)
        throw new IllegalStateException("Sorry, deque too big");
    Object[] a = new Object[newCapacity];
    System.arraycopy(elements, p, a, 0, r);
    System.arraycopy(elements, 0, a, r, p);
    elements = a;
    head = 0;
    tail = n;
}
```
<br/>

#### PriorityQueue
PriorityQueue  采用**数组结构**，底层采用了平衡二叉树实现堆的算法，来实现对优先级的控制，初始化容量为 11。
```Java
public class PriorityQueue<E> extends AbstractQueue<E>
    implements java.io.Serializable {
    private static final long serialVersionUID = -7720805057305804111L;

    private static final int DEFAULT_INITIAL_CAPACITY = 11;

    /** Priority queue represented as a balanced binary heap: the two
     * children of queue[n] are queue[2*n+1] and queue[2*(n+1)].  The
     * priority queue is ordered by comparator, or by the elements'
     * natural ordering, if comparator is null: For each node n in the
     * heap and each descendant d of n, n <= d.  The element with the
     * lowest value is in queue[0], assuming the queue is nonempty.*/
    transient Object[] queue; // non-private to simplify nested class access
    private int size = 0;

    /** The comparator, or null if priority queue uses elements'
     * natural ordering. */
    private final Comparator<? super E> comparator;
    transient int modCount = 0; // non-private to simplify nested class access

    /** Creates a {@code PriorityQueue} with the default initial
     * capacity (11) that orders its elements according to their
     * {@linkplain Comparable natural ordering}.*/
    public PriorityQueue() {
        this(DEFAULT_INITIAL_CAPACITY, null);
    }

    public PriorityQueue(int initialCapacity) {
        this(initialCapacity, null);
    }

    public PriorityQueue(Comparator<? super E> comparator) {
        this(DEFAULT_INITIAL_CAPACITY, comparator);
    }
    ……
}
```

PriorityQueue  的扩容，如果当前容量小于 64，则翻倍，否则增加 50%
```Java
/**
 * The maximum size of array to allocate.
 * Some VMs reserve some header words in an array.
 * Attempts to allocate larger arrays may result in
 * OutOfMemoryError: Requested array size exceeds VM limit
 */
private static final int MAX_ARRAY_SIZE = Integer.MAX_VALUE - 8;

private void grow(int minCapacity) {
    int oldCapacity = queue.length;
    // Double size if small; else grow by 50%
    int newCapacity = oldCapacity + ((oldCapacity < 64) ?
                                     (oldCapacity + 2) :
                                     (oldCapacity >> 1));
    // overflow-conscious code
    if (newCapacity - MAX_ARRAY_SIZE > 0)
        newCapacity = hugeCapacity(minCapacity);
    queue = Arrays.copyOf(queue, newCapacity);
}
```
<br/>

### 关于增删
#### LinkedList
LinkedList  增删见 List 小节。
<br/>

#### ArrayDeque
ArrayDeque  的增删，主要难点在于 head、tail 索引的移动。
通过查看 `addFirst()` , `addLast()`  以及 `removeFirst()` , `removeLast()` 的源代码观察 head、tail 的移动
```Java
public void addFirst(E e) {
    if (e == null)
        throw new NullPointerException();
    // 根据头索引，添加到头端，头索引-1
    elements[head = (head - 1) & (elements.length - 1)] = e;
    // 如果头索引和尾索引重复了，说明数组满了，进行扩容
    if (head == tail)
        doubleCapacity();
}

public void addLast(E e) {
    if (e == null)
        throw new NullPointerException();
    elements[tail] = e; // 根据尾索引，添加到尾端
    // 尾索引+1，如果尾索引和头索引重复了，说明数组满了，进行扩容
    if ( (tail = (tail + 1) & (elements.length - 1)) == head)
        doubleCapacity();
}
public E pollFirst() {
    int h = head;
    @SuppressWarnings("unchecked")
    E result = (E) elements[h];
    // Element is null if deque empty
    if (result == null)
        return null;
    elements[h] = null;     // Must null out slot
    // 头索引，删除队首元素，头索引+1
    head = (h + 1) & (elements.length - 1);
    return result;
}

public E pollLast() {
    // 尾索引，删除队尾元素，尾索引-1
    int t = (tail - 1) & (elements.length - 1);
    @SuppressWarnings("unchecked")
    E result = (E) elements[t];
    if (result == null)
        return null;
    elements[t] = null;
    tail = t;
    return result;
}
```

![](http://img.wenchao.wang/17-5-17/78761217-file_1494991695088_bcb2.jpg "arraydeque工作原理")

下表为 ArrayDeque  针对不同接口实现的方法

| 接口       | 方法            | 说明                      |
| -------- | ------------- | ----------------------- |
| 增        |               |                         |
| Deque 接口 | addFirst(e)   | 队首插入，错误抛出异常             |
|          | offerFirst(e) | 同 addFirst() ，错误返回false |
|          | addLast(e)    | 队尾插入，错误抛出异常             |
|          | offerLast(e)  | 同 addLast()，错误返回false   |
| Queue 接口 | add(e)        | 同addLast()              |
|          | offer(e)      | 同offerLast(e)           |
| Stack 接口 | push(e)       | 同addFirst(e)            |
| 删        |               |                         |
| Deque接口  | removeFirst() | 返回队首元素，并删除，错误抛出异常       |
|          | pollFirst()   | 返回队首元素，并删除              |
|          | removeLast()  | 返回队尾元素，并删除，错误抛出异常       |
|          | pollLast()    | 返回队尾元素，并删除              |
| Queue接口  | remove()      | 同removeFirst()          |
|          | poll()        | 同pollFirst()            |
| Stack接口  | pop()         | 同removeFirst()          |
| 查        |               |                         |
| Deque接口  | getFirst()    | 获取队首元素，错误抛出异常           |
|          | peekFirst()   | 获取队首元素                  |
|          | getLast()     | 获取队尾元素，错误抛出异常           |
|          | peekLast()    | 获取队尾元素                  |
| Queue接口  | element()     | 同getFisrt()             |
|          | peek()        | 同peekFirst()            |
| Stack接口  | peek()        | 同peekFirst()            |

<br/>

#### PriorityQueue
PriorityQueue  的增删，就是同平衡二叉树（即对堆）的操作，插入一个元素时，从堆尾插入，并不断的 shiftUp，删除一个元素时，就是将堆顶元素删除，然后用左右两个子树上的高优先级的元素替代，然后平衡。
```Java
public boolean offer(E e) {

    if (e == null)
        throw new NullPointerException();
    modCount++;
    int i = size;
    if (i >= queue.length)
        grow(i + 1);    // 如果容量已满，则扩容
    size = i + 1;
    if (i == 0)     // i=0, 表示插入的为第一个元素
        queue[0] = e;
    else
        siftUp(i, e);   // 从堆底插入，并不断上浮
    return true;
}
```

![](http://img.wenchao.wang/17-5-17/25938065-file_1495000803392_ce45.jpg "堆插入")

PriorityQueue  中的删除
```Java
public E poll() {
    if (size == 0)
        return null;
    int s = --size;
    modCount++;
    E result = (E) queue[0];    // 返回堆顶元素
    E x = (E) queue[s];
    queue[s] = null;
    if (s != 0)
        siftDown(0, x); 
    return result;
}
```

![](http://img.wenchao.wang/17-5-17/492735-file_1495000849424_11ae6.jpg "堆删除")
<br/>

### 关于查询
#### LinkedList
LinkedList  请看 List  小节
<br/>

#### ArrayDeque
ArrayDeque  的查询，如果仅仅是查询队首或队尾的元素，则只需要 O(1)  的时间。
ArrayDeque 不提供查询某一元素的方法，但是允许删除第一次遇到的某一元素，`removeFirstOccurrence` 和 `removeLastOccurrence` ，分别从队首和队尾开始循环查找，若找到，则删除。时间复杂度为 O(n) 。
```Java
public boolean removeFirstOccurrence(Object o) {
    if (o == null)
        return false;
    int mask = elements.length - 1;
    int i = head;
    Object x;
    while ( (x = elements[i]) != null) {
        if (o.equals(x)) {
            delete(i);
            return true;
        }
        i = (i + 1) & mask;
    }
    return false;
}
```
<br/>

#### PriorityQueue
PriorityQueue 下提供了查询方法 `contains()` , PriorityQueue  下的查询也是从数组头开始顺序查找的，时间复杂度为 O(n) ，具体实现如下
```java
private int indexOf(Object o) {
    if (o != null) {
        for (int i = 0; i < size; i++)
            if (o.equals(queue[i]))
                return i;
    }
    return -1;
}
```
<br/>

## Map
Map ，即映射表，或关联数组。Map  的基本思想是维护键-值关联（Key-Value，或 KV对） ，JDK  中提供多种 Map  实现，但行为特性、效率、键值对保存顺序、保存周期、多线程操作都不相同。

- `HashMap` ：最常用的结构，基于散列表 的实现。插入和查询 KV对 的开销是 O(1) 。可以通过构造器设置容量和负载因子调整容器性能
- `LinkedHashMap` ：类似 HashMap ，但迭代遍历时，取得 KV对 的顺序是插入顺序，或者是最近最少使用（LRU） 顺序。比 HashMap 稍慢，但在迭代访问时更快，因为其使用链表维护内部顺序。
- `TreeMap` ：基于红黑树实现，查看 KV 对 时，会被排序。TreeMap  的特点在于所得结果是经过排序的，也是唯一带有 subMap()  方法的 Map ，可以返回一个子树
- `EnumMap` ：Key  的类型必须为 enum  类型
- `WeakHashMap` ：弱键（weak key） 映射，允许释放映射所指向的对象；这是为解决某类特殊问题而设计的。如果映射之外没有引用指向某个 Key ，则该 Key  将被 GC  回收
- `IdentityHashMap` ：使用 ==  代替 equals() 对 Key  进行比较特殊的散列映射。为解决特殊问题设计。

![](http://img.wenchao.wang/17-5-17/23948756-file_1495001398540_17432.png)

<br/><br/>

# 参考资料
[1] 官方 List 接口文档 https://docs.oracle.com/javase/7/docs/api/java/util/List.html
[2] Oracle 文档 Interface Deque<E>，http://docs.oracle.com/javase/7/docs/api/java/util/Deque.html
[3] JDK源码研究PriorityQueue（优先队列），作者 十三月的，http://wlh0706-163-com.iteye.com/blog/1850125
[4] 白话经典算法系列之七 堆与堆排序，作者 MoreWindows，http://blog.csdn.net/morewindows/article/details/6709644
[5] Java PriorityQueue工作原理及实现，作者 Yikun，http://yikun.github.io/2015/04/07/Java-PriorityQueue%E5%B7%A5%E4%BD%9C%E5%8E%9F%E7%90%86%E5%8F%8A%E5%AE%9E%E7%8E%B0/
[6] jdk PriorityQueue优先队列工作原理分析, http://fangjian0423.github.io/2016/04/10/jdk_priorityqueue/
[7] jdk ArrayDeque工作原理分析  http://fangjian0423.github.io/2016/04/03/jdk_arraydeque/