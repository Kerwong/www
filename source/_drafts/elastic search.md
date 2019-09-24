*Elasticsearch* 是一个实时的分布式搜索分析引擎，被用作全文检索、结构化搜索、分析以及这三个功能的组合。Elasticsearch 是一个开源的搜索引擎，建立在一个全文搜索引擎库 Apache Lucene™ 基础之上。 Lucene 可以说是当下最先进、高性能、全功能的搜索引擎库--无论是开源还是私有。
Elasticsearch 也是使用 Java 编写的，它的内部使用 Lucene 做索引与搜索，但是它的目的是使全文检索变得简单， 通过隐藏 Lucene 的复杂性，取而代之的提供一套简单一致的 RESTful API。


- 一个分布式的实时文档存储，每个字段可以被索引与搜索
- 一个分布式实时分析搜索引擎
- 能胜任上百个服务节点的扩展，并支持 PB 级别的结构化或者非结构化数据



遵守  Apache 2 license



部署与启动

```sh
./bin/elasticsearch
curl 'http://localhost:9200/?pretty'
```

若返回 JSON 格式的 response，则说明正常启动了。



Elasticsearch 是 *面向文档* 的，意味着它存储整个对象或 *文档_。Elasticsearch 不仅存储文档，而且 _索引*每个文档的内容使之可以被检索。在 Elasticsearch 中，你 对文档进行索引、检索、排序和过滤--而不是对行列数据。









集群

一个集群是一组拥有相同 `cluster.name` 的节点， 他们能一起工作并共享数据，还提供容错与可伸缩性。

在 `elasticsearch.yml` 配置文件中 修改 `cluster.name` ，该文件会在节点启动时加载 (重启服务后才会生效)。







sysctl -w vm.max_map_count=262144



bound or publishing to a non-loopback address, enforcing bootstrap checks





报错：
 ERROR: bootstrap checks failed
 system call filters failed to install; check the logs and fix your configuration or disable system call filters at your own risk

原因：
 这是在因为Centos6不支持SecComp，而ES5.2.0默认bootstrap.system_call_filter为true进行检测，所以导致检测失败，失败后直接导致ES不能启动。

解决：
 在elasticsearch.yml中配置bootstrap.system_call_filter为false，注意要在Memory下面:
 bootstrap.memory_lock: false
 bootstrap.system_call_filter: false

可以查看issues
 <https://github.com/elastic/elasticsearch/issues/22899>

2、ERROR: bootstrap checks failed
 max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]

临时设置：sudo sysctl -w vm.max_map_count=262144
 永久修改：
 修改/etc/sysctl.conf 文件，添加 “vm.max_map_count”设置
 并执行：sysctl -p





max file descriptors [10240] for elasticsearch process is too low

**解决方法：**

以root权限，编辑/etc/security/limits.conf

 

添加如下内容:

 

$user soft nofile 65536

 

$user hard nofile 131072

 

注：$user 为ES启动用户







<https://www.elastic.co/guide/cn/kibana/current/settings.html>









<http://www.ruanyifeng.com/blog/2017/08/elasticsearch.html>