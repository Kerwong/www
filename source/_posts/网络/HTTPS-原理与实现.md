---
title: HTTPS 原理与实现
comments: true
date: 2016-12-23 15:35:47
tags:
- Https
---

在日常互联网浏览网页时，我们接触到的大多都是 HTTP 协议，这种协议是未加密，即明文的。这使得 HTTP  协议在传输隐私数据时非常不安全。因此，浏览器鼻祖 Netscape 公司设计了 `SSL（Secure Sockets Layer）` 协议，用于对 HTTP  协议传输进行数据加密，即 HTTPS 。

HTTPS 和HTTP 协议相比提供了：
- 数据完整性：内容传输经过完整性校验
- 数据隐私性：内容经过对称加密，每个连接生成一个唯一的加密密钥
- 身份认证：第三方无法伪造服务端（客户端）身份

SSL  目前版本是 3.0，之后升级为了 `TLS（Transport Layer Security）` 协议，TLS  目前为 1.2 版本。如未特别说明，SSL  与 TLS  均指同一协议。

<!-- more -->

# HTTPS 工作原理

## 网络通信（握手过程）
此图非常详尽的描述了 HTTPS 在通讯过程中的原理，总共分为 8 步。

![Https 原理](http://img.wenchao.wang/16-12-23/46844476-file_1482478921555_a8db.png "Https 原理")


### STEP 1: 客户端发起HTTPS 请求
SSL  连接总是由客户端启动，在 SSL  会话开始时，执行 SSL  握手。用户在浏览器里输入一个https 网址，然后连接到server 的443 端口。
客户端发送以下：
- 列出客户端密支持的加密方式列表（以客户端首选项顺序排序），如 SSL  的版本、客户端支持的加密算法和客户端支持的数据压缩方法(Hash 算法)。
- 包含 28 字节的随机数，`client_random`

以下是 Wireshark 抓包所得

```
Transmission Control Protocol, Src Port: 28258 (28258), Dst Port: 443 (443), Seq: 1, Ack: 1, Len: 517
    Source Port: 28258
    Destination Port: 443
    [Stream index: 13]
    [TCP Segment Len: 517]
    ......
Secure Sockets Layer
    TLSv1 Record Layer: Handshake Protocol: Client Hello
        // 握手记录
        Content Type: Handshake (22)
        // 0x0301 可以看出 TLS 是基于 SSL 3.1 构建而来
        Version: TLS 1.0 (0x0301)  
        Length: 512
        Handshake Protocol: Client Hello
            Handshake Type: Client Hello (1)
            Length: 508
            Version: TLS 1.2 (0x0303)
            Random
                GMT Unix Time: Jun 20, 2025 23:30:57.000000000 �й���׼ʱ��
                // 28 字节随机数 client_random
                Random Bytes: 12154d457c935c162fb8c0062572a5f84639b06289c51bf2...
            Session ID Length: 32
            // 可能为空，如果之前登陆过，则可以恢复之前的会话，避免一个完整的握手过程
            Session ID: c958100d8b678c0b071b54e977b456c06a233c08b9e2dd42...    
            Cipher Suites Length: 34
            // 密文族，列举浏览器所支持的加密算法清单
            Cipher Suites (17 suites)    
                Cipher Suite: Unknown (0xcca9)
                Cipher Suite: Unknown (0xcca8)
                Cipher Suite: TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256 (0xcc14)
                Cipher Suite: TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256 (0xcc13)
                Cipher Suite: TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256 (0xc02b)
                Cipher Suite: TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256 (0xc02f)
                Cipher Suite: TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384 (0xc02c)
                Cipher Suite: TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384 (0xc030)
                Cipher Suite: TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA (0xc009)
                Cipher Suite: TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA (0xc013)
                // 推荐使用
                Cipher Suite: TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA (0xc00a)    
                Cipher Suite: TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA (0xc014)
                Cipher Suite: TLS_RSA_WITH_AES_128_GCM_SHA256 (0x009c)
                Cipher Suite: TLS_RSA_WITH_AES_256_GCM_SHA384 (0x009d)
                Cipher Suite: TLS_RSA_WITH_AES_128_CBC_SHA (0x002f)
                Cipher Suite: TLS_RSA_WITH_AES_256_CBC_SHA (0x0035)
                Cipher Suite: TLS_RSA_WITH_3DES_EDE_CBC_SHA (0x000a)
            Compression Methods Length: 1
            Compression Methods (1 method)
                Compression Method: null (0)
            Extensions Length: 401
            Extension: renegotiation_info
                Type: renegotiation_info (0xff01)
                Length: 1
                Renegotiation Info extension
                    Renegotiation info extension length: 0
            Extension: server_name
                Type: server_name (0x0000)
                Length: 36
                Server Name Indication extension
                    Server Name list length: 34
                    Server Name Type: host_name (0)
                    Server Name length: 31
                    // 允许服务器对浏览器的请求授予相应的证书。
                    Server Name: images-cn.ssl-images-amazon.com    
            Extension: Extended Master Secret
                Type: Extended Master Secret (0x0017)
                Length: 0
            Extension: SessionTicket TLS
                Type: SessionTicket TLS (0x0023)
                Length: 192
                Data (192 bytes)
            Extension: signature_algorithms
                Type: signature_algorithms (0x000d)
                Length: 18
                Signature Hash Algorithms Length: 16
                // Hash 算法，用于签名
                Signature Hash Algorithms (8 algorithms)    
                    Signature Hash Algorithm: 0x0601
                        Signature Hash Algorithm Hash: SHA512 (6)
                        Signature Hash Algorithm Signature: RSA (1)
                    Signature Hash Algorithm: 0x0603
                        Signature Hash Algorithm Hash: SHA512 (6)
                        Signature Hash Algorithm Signature: ECDSA (3)
                    Signature Hash Algorithm: 0x0501
                        Signature Hash Algorithm Hash: SHA384 (5)
                        Signature Hash Algorithm Signature: RSA (1)
                    Signature Hash Algorithm: 0x0503
                        Signature Hash Algorithm Hash: SHA384 (5)
                        Signature Hash Algorithm Signature: ECDSA (3)
                    Signature Hash Algorithm: 0x0401
                        Signature Hash Algorithm Hash: SHA256 (4)
                        Signature Hash Algorithm Signature: RSA (1)
                    Signature Hash Algorithm: 0x0403
                        Signature Hash Algorithm Hash: SHA256 (4)
                        Signature Hash Algorithm Signature: ECDSA (3)
                    Signature Hash Algorithm: 0x0201
                        Signature Hash Algorithm Hash: SHA1 (2)
                        Signature Hash Algorithm Signature: RSA (1)
                    Signature Hash Algorithm: 0x0203
                        Signature Hash Algorithm Hash: SHA1 (2)
                        Signature Hash Algorithm Signature: ECDSA (3)
            Extension: status_request
                Type: status_request (0x0005)
                Length: 5
                Certificate Status Type: OCSP (1)
                Responder ID list Length: 0
                Request Extensions Length: 0
            Extension: signed_certificate_timestamp
                Type: signed_certificate_timestamp (0x0012)
                Length: 0
                Data (0 bytes)
            Extension: Application Layer Protocol Negotiation
                Type: Application Layer Protocol Negotiation (0x0010)
                Length: 14
                ALPN Extension Length: 12
                ALPN Protocol
                    ALPN string length: 2
                    ALPN Next Protocol: h2
                    ALPN string length: 8
                    ALPN Next Protocol: http/1.1
            Extension: channel_id
                Type: channel_id (0x7550)
                Length: 0
                Data (0 bytes)
            Extension: ec_point_formats
                Type: ec_point_formats (0x000b)
                Length: 2
                EC point formats Length: 1
                Elliptic curves point formats (1)
                    EC point format: uncompressed (0)
            Extension: elliptic_curves
                Type: elliptic_curves (0x000a)
                Length: 8
                Elliptic Curves Length: 6
                Elliptic curves (3 curves)
                    Elliptic curve: Unknown (0x001d)
                    Elliptic curve: secp256r1 (0x0017)
                    Elliptic curve: secp384r1 (0x0018)
            Extension: Padding
                Type: Padding (0x0015)
                Length: 77
                Padding Data: 000000000000000000000000000000000000000000000000...
                    Padding length: 0
                    Padding Data: <MISSING>
```

<br/>



### STEP 2: 服务端的配置

采用HTTPS 协议的服务器必须要有一套数字证书，可以自己制作，也可以向组织申请。区别就是自己颁发的证书需要客户端验证通过，才可以继续访问，而使用受信任的公司申请的证书则不会弹出提示页面。这套证书其实就是一对公钥和私钥。
** 如果对公钥和私钥不太理解，可以想象成一把钥匙和一个锁头，只是全世界只有你一个人有这把钥匙，你可以把锁头给别人，别人可以用这个锁把重要的东西锁起来，然后发给你，因为只有你一个人有这把钥匙，所以只有你才能看到被这把锁锁起来的东西。** 客户端和服务器至少必须支持一个公共密码对，否则握手失败。服务器一般选择最大的公共密码对。

<br/>

### STEP 3: 传送证书
服务器端返回以下：
- 服务器端选出的一套加密算法和 Hash  算法
- 服务器生成的随机数 `server_random`
- `SSL`  数字证书（服务器使用带有 `SSL`  的 `X.509 V3`  数字证书），这个证书包含网站地址，公钥 `public_key` ，证书的颁发机构，过期时间等等。

```
Transmission Control Protocol, Src Port: 443 (443), Dst Port: 28258 (28258), Seq: 1, Ack: 518, Len: 137
    Source Port: 443
    Destination Port: 28258
    [Stream index: 13]
    [TCP Segment Len: 137]
    Sequence number: 1    (relative sequence number)
    [Next sequence number: 138    (relative sequence number)]
    Acknowledgment number: 518    (relative ack number)
    Header Length: 20 bytes
    Flags: 0x018 (PSH, ACK)
    ......
Secure Sockets Layer
    TLSv1 Record Layer: Handshake Protocol: Server Hello
        Content Type: Handshake (22)
        Version: TLS 1.0 (0x0301)
        Length: 81
        Handshake Protocol: Server Hello
            Handshake Type: Server Hello (2)
            Length: 77
            Version: TLS 1.0 (0x0301)
            Random
                GMT Unix Time: Mar  1, 2090 17:07:25.000000000 �й���׼ʱ��
                // 28 字节的随机数 server_random
                Random Bytes: 903945ed14db8e4151d651814ed7067c0e9c115d94ff6af7...    
            Session ID Length: 32
            Session ID: c958100d8b678c0b071b54e977b456c06a233c08b9e2dd42...
            // 加密族中，服务器最终选择了这个。意味着服务器之后会使用 RSA 公钥加密算法来区分证书签名和交换密钥，通过 3DES 加密算法来加密数据，通过 SHA 算法来校验信息
            Cipher Suite: TLS_RSA_WITH_3DES_EDE_CBC_SHA (0x000a)    
            Compression Method: null (0)
            Extensions Length: 5
            Extension: renegotiation_info
                Type: renegotiation_info (0xff01)
                Length: 1
                Renegotiation Info extension
                    Renegotiation info extension length: 0
    TLSv1 Record Layer: Change Cipher Spec Protocol: Change Cipher Spec
        Content Type: Change Cipher Spec (20)
        Version: TLS 1.0 (0x0301)
        Length: 1
        Change Cipher Spec Message
            [Expert Info (Note/Sequence): This session reuses previously negotiated keys (Session resumption)]
                [This session reuses previously negotiated keys (Session resumption)]
                [Severity level: Note]
                [Group: Sequence]
    TLSv1 Record Layer: Handshake Protocol: Encrypted Handshake Message
        Content Type: Handshake (22)
        Version: TLS 1.0 (0x0301)
        Length: 40
        Handshake Protocol: Encrypted Handshake Message
```

<br/>

### STEP 4: 客户端解析证书

这部分工作是由客户端的`TLS` 来完成的。
1. 首先会验证证书是否有效，这是对服务端的一种认证，比如颁发机构，过期时间等等，如果发现异常，则会弹出一个警告框，提示证书存在问题。
2. 如果证书没有问题，那么浏览器根据步骤 3 的 `server_random`  生成一个随机值 `premaster_secret` （前 2 个字节是协议版本号，后 46 字节是用在对称加密密钥的随机数字）和 `master_secret 。 master_secret`  的生成需要 `premaster_key` ，并需要 `client_random`  和 `server_random`  作为种子
  ```
  master_secret = PRF(pre_master_secret, "master secret", client_random + server_random)
  ```
  现在，各方面已经有了主密钥 `master_secret` ，根据协议约定，我们需要利用`PRF` 生成这个会话中所需要的各种密钥，称之为“密钥块”（Key Block ）：
  ```
  key_block = PRF(SecurityParameters.master_secret, "key expansion", SecurityParameters.server_random + SecurityParameters.client_random);
  密钥块用于构成以下密钥：
  client_write_MAC_secret[SecurityParameters.hash_size]
  server_write_MAC_secret[SecurityParameters.hash_size]
  client_write_key[SecurityParameters.key_material_length]
  server_write_key[SecurityParameters.key_material_length]
  client_write_IV[SecurityParameters.IV_size]
  server_write_IV[SecurityParameters.IV_size]
  ```
  这是由系列 Hash  值组成，它将作为数据加解密相关的Key Material ，包含六部分内容，分别是用于校验一致性的密钥，用于对称内容加解密的密钥，以及初始化向量，客户端和服务器端各一份。其中，`write MAC key` ，就是`session secret` 或者说是`session key` 。`Client write MAC key` 是客户端发数据的`session secret` ，`Server write MAC secret` 是服务端发送数据的`session key` 。`MAC(Message Authentication Code)` ，是一个数字签名，用来验证数据的完整性，可以检测到数据是否被串改。然后用证书公钥 `public_key`  对该随机值进行加密。就好像上面说的，把随机值用锁头锁起来，这样除非有钥匙，不然看不到被锁住的内容。
3. Hash  握手信息，用第3步返回约定好的 Hash  算法对握手信息取 Hash 值，然后用随机数加密“握手消息+握手消息 Hash  值（签名）”

<br/>

### STEP 5: 传送加密信息

客户端发送以下：
- 客户端发送公钥 `public_key`  加密的 `premaster secret` 。目的就是让服务端得到这个随机值，以后客户端和服务端的通信就可以通过这个随机值来进行加密解密了。

<br/>

### STEP 6: 服务端解密信息
服务端用私钥 `private_key`  解密后，得到了客户端传过来的随机值 `premaster_secret(私钥)`，又由于服务器在步骤 1 中收到的 `client_random` ，所以服务器根据相同的生成算法，在相同输入参数的情况下，得到相同的 `master_secret` 。然后把内容通过该值进行对称加密。
所谓对称加密就是，将信息和私钥通过某种算法混合在一起，这样除非知道私钥，不然无法获取内容，而正好客户端和服务端都知道这个私钥，所以只要加密算法够彪悍，私钥够复杂，数据就够安全。

<br/>

### STEP 7: 传输加密后的信息
服务器端返回以下：
将被 `premaster_key`  对称加密的信息返回客户端，客户端可还原

<br/>

### STEP 8: 客户端解密信息
客户端用之前生成的私钥解密服务段传过来的信息，于是获取了解密后的内容。整个过程第三方即使监听到了数据，也束手无策。

<br/>

## SSL/TLS
![TCP/IP协议栈中TLS各子协议和HTTP的关系](http://img.wenchao.wang/16-12-23/41896347-file_1482479295543_e062.png "TCP/IP协议栈中TLS各子协议）和HTTP的关系")

HTTPS 可以认为是 HTTP + TLS。TLS 是传输层加密协议TLS 协议本身又是由 record 协议传输的，record 协议的格式如下图
![general-format-of-all-TLS-records](http://img.wenchao.wang/16-12-23/13708164-file_1482479427710_1095.png "general-format-of-all-TLS-records")

TLS 协议主要有五种类型 Content Type：
Content types

| Hex  | Dec  | Type                      |
| ---- | ---- | ------------------------- |
| 0x14 | 20   | 加密消息确认协议 ChangeCipherSpec |
| 0x15 | 21   | 报警协议 Alert                |
| 0x16 | 22   | 握手协议 Handshake            |
| 0x17 | 23   | 应用数据层协议 Application       |
| 0x18 | 24   | 心跳协议 Heartbeat            |

<br/>

## 加密方式

加密算法一般分为对称加密与非对称加密。

### 对称加密
客户端与服务器使用相同的密钥对消息进行加密
优点：
- 加密强度高，很难被破解
- 计算量小，仅为非对称加密计算量的 0.1%

缺点：
- 无法安全的生成和管理密钥
- 服务器管理大量客户端密钥复杂

<br/>

### 非对称加密
非对称指加密与解密的密钥为两种密钥。服务器提供公钥，客户端通过公钥对消息进行加密，并由服务器端的私钥对密文进行解密。

优点：安全

缺点
- 性能低下，CPU 计算资源消耗巨大，一次完全的 TLS 握手，密钥交换时的非对称加密解密占了整个握手过程的 90% 以上。而对称加密的计算量只相当于非对称加密的 0.1%，因此如果对应用层使用非对称加密，性能开销过大，无法承受。
- 非对称加密对加密内容长度有限制，不能超过公钥的长度。比如现在常用的公钥长度是 2048 位，意味着被加密消息内容不能超过 256 字节。

<br/>

### HTTPS 下的加密
HTTPS一般使用的加密与HASH算法如下：
- 非对称加密算法：`RSA`，`DSA/DSS`
- 对称加密算法：`AES`，`RC4`，`3DES`
- HASH算法：`MD5`，`SHA1`，`SHA256`

其中非对称加密算法用于在握手过程中加密生成的密码，对称加密算法用于对真正传输的数据进行加密，而HASH算法用于验证数据的完整性。由于浏览器生成的密码是整个数据加密的关键，因此在传输的时候使用了非对称加密算法对其加密。非对称加密算法会生成公钥和私钥，公钥只能用于加密数据，因此可以随意传输，而网站的私钥用于对数据进行解密，所以网站都会非常小心的保管自己的私钥，防止泄漏。
TLS握手过程中如果有任何错误，都会使加密连接断开，从而阻止了隐私信息的传输。正是由于HTTPS非常的安全，攻击者无法从中找到下手的地方，于是更多的是采用了假证书的手法来欺骗客户端，从而获取明文的信息，但是这些手段都可以被识别出来

<br/>

## 关于证书
证书需要申请，并由专门的数字证书认证机构 CA 通过非常严格的审核之后颁发的电子证书，证书是对服务器端的一种认证。颁发的证书同时会产生一个私钥和公钥。私钥有服务器自己保存，不可泄露，公钥则附带在证书的信息中，可以公开。证书本身也附带一个证书的电子签名，这个签名用来验证证书的完整性和真实性，防止证书被篡改。此外证书还有个有效期。
证书包含以下信息：
- 使用者的公钥值。
- 使用者标识信息（如名称和电子邮件地址）。
- 有效期（证书的有效时间）。
- 颁发者标识信息。
- 颁发者的数字签名，用来证明使用者的公钥和使用者的标识符信息之间的绑定的有效性。

<br/>

# 参考资料
[1] Wiki 关于 Transport Layer Security 的介绍，https://en.wikipedia.org/wiki/Transport_Layer_Security
[2] 大型网站的 HTTPS 实践（一）—— HTTPS 协议和原理 http://op.baidu.com/2015/04/https-s01a01/
[3] SSL工作原理 https://www.wosign.cn/Basic/howsslwork.htm
[4] SSL/TLS协议运行机制的概述 http://www.ruanyifeng.com/blog/2014/02/ssl_tls.html
[5] HTTPS工作原理，猫尾博客，https://cattail.me/tech/2015/11/30/how-https-works.html
[6] HTTPS那些事（一）HTTPS原理，晓风残月，http://www.guokr.com/post/114121/
[7] HTTPS证书生成原理和部署细节，小胡子哥，http://www.barretlee.com/blog/2015/10/05/how-to-build-a-https-server/
