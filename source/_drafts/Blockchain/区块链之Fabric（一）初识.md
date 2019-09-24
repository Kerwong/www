---
title: '区块链之Fabric（一）初识'
date: 2018-03-20 21:44:24
tags: 
- Blockchain
- Hyperledger Fabric
---



Hyperledger Fabric 项目是 Linux 基金会牵头，众多巨头企业参与的分布式账本项目，Hyperledger 含义就是超级（Hyper-）账本（Ledger）。Hyperledger Fabric 项目立项至今已有 2年多，终于在 2018.3.20 日，发布了其 release 1.1 版本。

Hyperledger 下有一系列的顶级项目，Fabric 是最主要的。Hyperledger Fabric 是用 Go 语言实现，代码量已有 8万行，包括子项目 Fabric CA、Fabric SDK 等。它的优点的话，有[文章](https://www.ibm.com/developerworks/cn/cloud/library/cl-top-technical-advantages-of-hyperledger-fabric-for-blockchain-networks/index.html)总结：

- 联盟链的许可管理
- 高性能、可伸缩性和高信任水平
- 以“需要知道”为原则来公开数据
- 对不可变分布式账本的丰富查询
- 支持插件组件的模块化架构
- 保护数字密钥和敏感数据



Hyperledger 下还有些其他顶级项目，如：

- Sawtooth 是由 Intel 提交的基于 Python 的分布式账本平台；利用 Intel 芯片，实现了低功耗的 Proof of Elasped Time（PoET）共识
- Blockchain Explorer 是 Node.js 实现的区块链平台浏览器
- Cello 是 IBM 提交的区块链管理平台项目，提供 BaaS（Blockchain as a Service）服务和管理、维护等功能

Blockchain Explorer 和 Cello 对我们也会有些借鉴作用，留作日后的调研任务。本文及之后的几篇文章，将先介绍 Fabric。



从现有 Fabric 项目总结，可以说是复杂难用，功能不强。作为区块链时代重要的一条分支，联盟链的扛鼎之作，厂里也投了点钱于去年成为了会员，但以项目当前推进效率，估计明年也不续费了。



<!--more-->

![](https://wiki.hyperledger.org/_media/projects/hyperledger_fabric_logo_color.png)

对于知道 Fabric 的同学，想必已经对区块链有了初步的了解，什么共识、块和链云云的基础概念，就不再赘述。这是 Fabric 系列文章的第一篇，将对 Fabric 做总体概述，帮助后来人能对此与一清晰的认识，我发现我在尝试部署过程中，由于没有清晰的概念，常常手足无措，而网上找的文章，行文组织实在不方便初学者理解。



# Fabric 总览



## Peers

Fabric 中 `Peer` 是网络中最基础的部分，是用于管理 `账本 ledger` 和`智能合约 smart contract 或称为 chaincode` 实例。

Peer 可被创建、启动、停止、配置、删除。Peer 对外暴露 API，供 client 或 其他 Peer 调用。

账本 ledger 永久的存储 smart contract 产生的交易，每个 peer 都保存了 ledger 和 chaincode 的备份。如下图，在区块链网络 N 中，有三个 Peer， P1, P2, P3 管理着同样的智能合约 S1, 账本 L1。

![](http://img.wenchao.wang/18-3-29/95708787.jpg)

> 一个 Peer 允许保留多个 ledger 和多个 chaincode。同一 chaincode 也可以访问不同 ledger

<br/>

### Channel & Org

`Channel` 可以理解为是 Fabric 联盟链中的某一条子链。channel 互相独立，为特定的某一功能的 Peer 集合服务。

App 与 Peer、Peer 与Peer 间通过 channel 通信，channel 之间彼此独立，**不可跨链通信**。

![](http://img.wenchao.wang/18-3-29/70042549.jpg)

各个 Peer 和 App 可以组织为 `Organization`。上图有 Org1, Org2, Org3, Org4 四个 Org。

Org1 含 App A1，Peer P1, P2。Org2, Org3, Org4 类似。

App 可连所属的 Org 的节点，也可以连接其他 Org 的节点。一般查询只需要连自己所在 Org，而写入时，需要连其他 Org 的 Peer 进行背书。

**Peer 仅可归属于一个 Org**，App 可归属于多个 Org。

<br/>

### Identity

对于 Peer 的权限管理，是由一个称为 MSP 的组件完成的。Fabric 中，对于权限的管理，是通过 CA，MSP 是一个验证 CA 的组件。

在网络初始时，会根据配置文件初始化一系列的证书，包括 channel 的和 Peer 的。位于同 channel 下的 Peer 中的关于 channel 的配置是一致的，用来管理 Peer 在 channel 中的权限。对于每个 Org，也会有相应的权限管理。

Peer 的身份或者称权限由 MSP 授予。由于 peer 只属于一个 Org，因此只会与一个 MSP 关联。

关于 CA 和 MSP，将在下文进一步介绍。

![](http://img.wenchao.wang/18-3-29/91608274.jpg)

### 提案、背书、排序、入链

Fabric 网络中提供 orderer 节点，orderer 的功能是对提案进行入链前的排序，所有 Peer 将以 orderer 的结果将提案写入账本。



整个提案至入链的过程，总共分为以下三步：

#### Phase 1：提案

1. APP 产生交易提案
2. APP 根据背书策略（Endorsement policy，定义了提案被接受前需要提供背书的 Org 集合）向多个 Peer 节点（隶属于同 channel 下的不同的 Org）发起背书请求
3. 背书节点独立执行 chaincode，若背书成功，则背书节点签名，并返回结果
4. APP 等待返回，若返回背书结果满足多数派条件，则 Phase 1 完成；若不满足，则丢弃此次提案

![](http://img.wenchao.wang/18-3-29/61605614.jpg)

<br/>

#### Phase 2：打包

1. APP 将通过背书的提案发送至 Orderer 节点，多个APP 会并行向 Orderer 节点发送提案
2. Orderer 会接收多 channel 渠道来的提案，Orderer 会并发处理各个 channel 的提案。节点对提案进行打包，出块。出块由时间和块交易大小决定
3. 出块后，Orderer 将块发往 channel

![](http://img.wenchao.wang/18-3-29/94444880.jpg)

<br/>

#### Phase 3：验证

1. Orderer 节点通过 channel 向 peer 分发块
2. peer 收到块后，执行交易，每一笔交易都将检验背书
3. peer 检查当前账本一致性
4. peer 将块入链
5. peer 于 Org 内广播入链事件

> peer 间还可通过 gossip 协议同步块信息



![](http://img.wenchao.wang/18-3-29/47077633.jpg)

<br/>

## 账本 Ledger

区块链的账本，是一个有序的，不可被篡改的状态数据，状态的变化的汇总形成了最终的数据。

因此 ledger 包含了两部分

- 用来保存当前值的`world state` ，KV 对形式存在，可增删改查。
- `blockchain`，交易日志，记录所有交易变化。不可改，有序



> 每个 channel 有且仅有一个账本



Fabric 下的 Ledger 整体结构与其他区块链并没太大差异，都是 Merkle-Tree，块 HEAD 包含前一个块 Hash 云云。不再赘述。

<br/>

## 权限控制 CA & MSP

Fabric 是联盟链，其对区块链网络的权限和隐私要求比较严格，不同于公有链各节点地位同等，Fabric 在整个网络中，分为 peer、orderer、client application、administrator 等各类角色，各个角色的权限也是不同的。

> 那该如何区分、控制权限呢？
>
> Fabric 通过 CA 和 MSP 实现。

<br/>

### Certificate Authorities

CA (Certificate Authorities，证书授权)  就是一张许可证，好比是进入公司的工卡，进入小区的门禁卡，只有获得了相应的 CA，才拥有了相应权限。CA 包含机构的地址、用于解密的公钥，一些算法和规定等。

CA (Certificate Authorities，证书授权) 证书由  `PKI ` 基础服务颁发。Fabric 提供了应用程序 `cryptogen` 根据配置文件 `crypto-config.yaml` 来生成证书。

以下是 cryptogen 生成的某一份证书，通过 `openssl x509 -in ca.org1.example.com-cert.pem -text -noout` 查看

```
[work@gzhxy-fsg-fpu-hyperledger01 ca]$ openssl x509 -in ca.org1.example.com-cert.pem -text -noout
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            50:01:2a:88:22:75:bb:72:b7:0d:51:0e:4a:db:f6:3f
    Signature Algorithm: ecdsa-with-SHA256
        Issuer: C=US, ST=California, L=San Francisco, O=org1.example.com, CN=ca.org1.example.com
        Validity
            Not Before: Mar 29 11:35:48 2018 GMT
            Not After : Mar 26 11:35:48 2028 GMT
        Subject: C=US, ST=California, L=San Francisco, O=org1.example.com, CN=ca.org1.example.com
        Subject Public Key Info:
            Public Key Algorithm: id-ecPublicKey
                Public-Key: (256 bit)
                pub:
                    04:ea:f5:da:dd:92:92:51:52:dd:49:2b:fe:6a:2e:
                    f1:97:40:cd:67:7b:76:43:ef:83:1c:f6:5e:f4:c3:
                    b8:d0:46:d3:a8:c4:58:5a:d5:0f:28:a9:ae:78:54:
                    68:8a:94:da:dd:77:46:ab:fd:6b:46:ec:f3:d7:70:
                    c5:cb:8c:42:e0
                ASN1 OID: prime256v1
                NIST CURVE: P-256
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment, Certificate Sign, CRL Sign
            X509v3 Extended Key Usage:
                Any Extended Key Usage
            X509v3 Basic Constraints: critical
                CA:TRUE
            X509v3 Subject Key Identifier:
                F6:BB:4B:31:BA:23:34:A6:F2:16:40:C8:21:B2:ED:94:34:61:96:7E:AE:28:66:EE:F4:D2:72:92:FC:EA:B9:33
    Signature Algorithm: ecdsa-with-SHA256
         30:44:02:20:47:39:97:d4:fb:8a:5e:30:e1:3a:a9:85:4c:e8:
         dc:5c:5b:c2:cd:ae:a7:92:55:69:b6:07:25:49:97:2b:ef:14:
         02:20:6e:df:b5:be:9c:3b:22:a3:da:ec:e4:95:63:40:1e:a7:
         39:9c:57:11:69:52:0e:00:04:24:62:47:49:67:81:19
```



由于 CA 对于 Fabric 非常重要，因此 Fabric 提供了组件 `fabric-ca`  作为 PKI 基础服务用来于区块链网络内部生成颁发证书。

显然，区块链内部颁发的证书是私有的，是无法被浏览器等认可的。

<br/>

证书可以颁发，自然也应允许被废除，废除的证书被维护在一个 Certificate Revocation List (CRL) 列表中。CRL 是 PKI 一部分，当校验证书时，会先查询 CRL 列表。

![](http://img.wenchao.wang/18-4-8/13594412.jpg)



不过，由于 CA 的整套组件还是比较繁杂的，Fabric 允许在简单部署时，无 fabric-ca。生成文件后一次性分发至各方即可。

<br/>



### **Membership Service** Provider

CA 是作为 Fabric 网络中，各方使用的 “工卡” 或 “门禁卡”，但仅仅有各种权限的“卡”，并无法构成一个闭环。还需要有校验卡权限的门卫，对于 Fabric，也就是 `MSP`。

> MSP: it identifies which Root CAs and Intermediate CAs are trusted to define the members of a trust domain, e.g., an organization
>
> 摘自 http://hyperledger-fabric.readthedocs.io/en/latest/membership/membership.html

MSP 就是用来判断 CA 是否有效，是否属于该组织，在组织中是什么角色身份的**组件**。具体点，就是一堆证书和私钥



一个 Org 一般只配一个 MSP，用来管理该 Org 下所有会员（即该 Org 下的各类节点）。

但有时，一些 Org 会在内部形成不同的职能群体，此时可以配置多个 MSP，不同的 MSP 管理不同的会员（即该 Org 下的各类节点被再次划分，由不同的 MSP 管理）



根据 MSP 管辖范畴，可以将 MSP 分为：

- channel MSP，管理所有参与 channel 的 Org 或 Org Unit。
  - channel MSP 配置于 channel configuration（配置文件 `configtx.yaml`）
  - Org 之间会组成联合体，称为 `Organization Units（OUs）` 。channel MSP 也可直接对 `OU` 进行管理，例如限制 OU  `ORG1-MANUFACTURING` 的权限。
  - channel MSP 的配置在 channel 初始化时会与参与该 channel 的所有 Org 下的所有各节点以及 orderers 共享，使得各个节点可以管理 channel 其他参与者的权限，见下图。
  - channel MSP 通过共识于各个节点间同步
  - channel MSP 物理上，保存于该 channel 下的所有节点中。
- ILocal MSP，用于管理各个节点，如 Peer、orderer、client 的权限，规定了节点在组织中的身份，组织中管理者的身份等。
  - 位于 Peer、Orderer、client 的本地
  - 每个节点都**必须**有一个 local MSP
  - local MSP 仅保存在节点的文件系统中。

<br/>

![](http://img.wenchao.wang/18-4-8/72614863.jpg)

<br/>

MSP 位于 `/etc/hyperledger/fabric` 下，以文件格式存在 ，包含以下九部分：

```
root@936eca985f99:/etc/hyperledger/fabric# tree msp
msp
|-- admincerts				# administrator certificate
|   `-- admincert.pem		 
|-- cacerts					# root CA’s certificate
|   `-- cacert.pem
|-- intermediatecerts		 # (optional) intermediate CA’s certificate
|-- config.yaml				# (optional) contain a list of organizational units
|-- crls					# (optional) Certificate Revocation List
|-- keystore				# for the local MSP of a peer or orderer node (or in an client’s local MSP), and contains the node’s signing key
|   `-- key.pem
|-- signcerts				# PEM file with the node’s X.509 certificate
|   `-- peer.pem
|-- tlscacerts				# (optional) list of self-signed X.509 certificates of the Root CAs trusted by this organization for TLS communications
|   `-- tlsroot.pem
`-- tlsintermediatecerts	# (optional) list intermediate CA certificates CAs trusted by the organization represented by this MSP for TLS communications
    `-- tlsintermediate.pem
```

<br/>

# 术语

| 术语 en                             | 术语 zh | 含义                                       |
| --------------------------------- | ----- | ---------------------------------------- |
| Anchor Peer                       | 锚节点   | 机构指定用于通道上的与其他机构节点的通信用的节点                 |
| Chaincode                         | 链码    | 智能合约，现支持 Go 和 Nodejs                     |
| Channel                           | 通道    | 可以理解为区块链子网，机构需授权才可加入通道，同通道内的节点间可通信       |
| Concurrency Control Version Check |       | 用于交易执行和提交时的事务控制，用于保证不出现脏读                |
| Configuration Block               | 配置块   | 记录排序服务或通道的机构和策略。所有如机构的新增和退出，都会为配置链新增配置块，链的配置为 genesis block + delta |
| Dynamic Membership                | 动态会员  |                                          |

<br/><br/>

# 参考资料

[1] 面向区块链网络的 Hyperledger Fabric 的 6 大技术优势，[Sharon Cocco](https://www.linkedin.com/in/sharon-weed-cocco-a4a19b69/) 和 [Gari Singh](https://www.linkedin.com/in/garisingh/)， https://www.ibm.com/developerworks/cn/cloud/library/cl-top-technical-advantages-of-hyperledger-fabric-for-blockchain-networks/index.html

[2] https://hyperledger-fabric.readthedocs.io/en/release-1.1/peers/peers.html