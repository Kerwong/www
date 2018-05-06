---
title: '区块链之Fabric（三）动态增删机构'
date: 2018-04-09 11:09:36
tags: 
- Blockchain
- Hyperledger Fabric
---



Fabric 是联盟链，一个 channel 就好比一个联盟，如果有新的机构需要加入，则必须得到联盟内的成员的认可。

正是基于这样的场景，fabric 在为 channel 新增 org 时，会涉及诸多的权限和证书操作。

<br/>

为 Channel 动态新增 Org 有以下几步：

1. 为新 org 生成证书
2. 为新 org 生成配置文件
3. 生成和提交新 org 的配置
   1. `peer channel fetch config` 创建添加新 org 的配置交易，为网络新增 org
   2. `peer channel signconfigtx` 为配置交易签名，需网络中 **MAJORITY**  的 org 都签名
   3. `peer channel update` 提交签名后的配置交易至 orderer
4. 将新 org 添加入 channel
   1. 启动新 org 集群，一般会有一个 cli 和多个 peer
   2. `peer channel fetch`  于 cli 中从 orderer 中获取 channel 创世块
   3. `peer channel join` 将新 org 下的 peer 加入 channel
5. 升级chaincode和背书策略
   1. `peer chaincode install` 为新 org 的 peer 安装 chaincode，于新 org 的 cli 中完成
   2. `peer chaincode install`, 为其他 org 升级 chaincode，于原 org 的 cli 中完成
   3. `peer chaincode upgrade` 升级背书策略，于原 org 的 cli 中完成
6. 测试是否成功




此文基于 Fabric v1.1，通过 fabric-samples 下的 first-network 样例为基础，在其区块链网络上，为通道 mychannel 新增一个 Org3，Org3 包含两个 peer。

<!--more-->

# 初始环境

fabric-samples 地址为 https://github.com/hyperledger/fabric-samples ， 本文采用其中的 first-network 实验。

first-network 启动后，会默认创建 1 个 orderer 节点，4个 peer 节点（其中 2个属于 org1，2个属于 org2），并提供一个 cli 用于相关操作。



`docker ps` 之后输出如下：

```
CONTAINER ID        IMAGE                                                                                                  COMMAND                  CREATED              STATUS              PORTS                                              NAMES
a36d576296f4        dev-peer1.org2.example.com-mycc-1.0-26c2ef32838554aac4f7ad6f100aca865e87959c9a126e86d764c8d01f8346ab   "chaincode -peer.add…"   About a minute ago   Up About a minute                                                      dev-peer1.org2.example.com-mycc-1.0
70789dd829f0        dev-peer0.org1.example.com-mycc-1.0-384f11f484b9302df90b453200cfb25174305fce8f53f4e94d45ee3b6cab0ce9   "chaincode -peer.add…"   About a minute ago   Up About a minute                                                      dev-peer0.org1.example.com-mycc-1.0
c961ab191471        dev-peer0.org2.example.com-mycc-1.0-15b571b3ce849066b7ec74497da3b27e54e0df1345daff3951b94245ce09c42b   "chaincode -peer.add…"   About a minute ago   Up About a minute                                                      dev-peer0.org2.example.com-mycc-1.0
8314e683df95        hyperledger/fabric-tools:latest                                                                        "/bin/bash"              About a minute ago   Up About a minute                                                      cli
c80bb0cdbb3e        hyperledger/fabric-peer:latest                                                                         "peer node start"        About a minute ago   Up About a minute   0.0.0.0:8051->7051/tcp, 0.0.0.0:8053->7053/tcp     peer1.org1.example.com
656efc4c4b94        hyperledger/fabric-orderer:latest                                                                      "orderer"                About a minute ago   Up About a minute   0.0.0.0:7050->7050/tcp                             orderer.example.com
1f6777d60647        hyperledger/fabric-peer:latest                                                                         "peer node start"        About a minute ago   Up About a minute   0.0.0.0:10051->7051/tcp, 0.0.0.0:10053->7053/tcp   peer1.org2.example.com
8be768d5aed0        hyperledger/fabric-peer:latest                                                                         "peer node start"        About a minute ago   Up About a minute   0.0.0.0:9051->7051/tcp, 0.0.0.0:9053->7053/tcp     peer0.org2.example.com
0680044f68b9        hyperledger/fabric-peer:latest                                                                         "peer node start"        About a minute ago   Up About a minute   0.0.0.0:7051->7051/tcp, 0.0.0.0:7053->7053/tcp     peer0.org1.example.com
```

<br/>

# 自动化动态添加

first-network 直接提供了自动化添加的脚本 `eyfn.sh`。执行 `./eyfn.sh up` 即可自动化为 channel 添加 org3。此法因不具扩展性，且不方便理解 fabric，因此不再赘述。以下是执行后的输出，若成功，会输出  `All GOOD` 。

```
[work@gzhxy-fsg-fpu-hyperledger01 first-network]$ ./eyfn.sh up
Starting with channel 'mychannel' and CLI timeout of '10' seconds and CLI delay of '3' seconds
Continue? [Y/n] Y
proceeding ...
/home/work/go/src/github.com/hyperledger/fabric/release/linux-amd64/bin/cryptogen
... ...
... ...
... ...
2018-04-09 03:37:24.644 UTC [msp/identity] Sign -> DEBU 007 Sign: digest: 1B7235C3DC2AF4B066928DDEA387D4A0524357DEB4978C23DB70B01B893DBC3A
Query Result: 80
2018-04-09 03:37:24.651 UTC [main] main -> INFO 008 Exiting.....
===================== Query on peer0.org3 on channel 'mychannel' is successful =====================
========= All GOOD, EYFN test execution completed ===========
 _____   _   _   ____
| ____| | \ | | |  _ \
|  _|   |  \| | | | | |
| |___  | |\  | | |_| |
|_____| |_| \_| |____/
```

> 虽然不赘述 eyfn.sh，但脚本和手动部署原理是一致的，可以仔细学习。

<br/>

# 为 channel 动态添加 Org

## step1: 为新 org 生成证书

```shell
cd org3-artifacts/
cryptogen generate --config=./org3-crypto.yaml
```

会依据 `org3-crypto.yaml` 生成，生成后的文件位于 org3-artifacts/crypto-config/ 下

org3-crypto.yaml 文件中 Org3 的配置如下：

```yaml
PeerOrgs:
  - Name: Org3
    Domain: org3.example.com
    EnableNodeOUs: true
    Template:
      Count: 2
    Users:
      Count: 1
```

<br/>

## step2: 为新 org 生成配置文件

### 导入配置

```shel
export FABRIC_CFG_PATH=$PWD
```
<br/>

### 将 org3 的配置以 json 格式输出

`configtxgen` 命令会从 `configtx.yaml` 读取 Org3 相关配置，生成 json 输出至 org3.json

```shell
configtxgen -printOrg Org3MSP -profile ./configtx.yaml > ../channel-artifacts/org3.json
```

若成功，输出如下：

```
2018-04-09 17:03:12.625 CST [common/tools/configtxgen] main -> INFO 001 Loading configuration
2018-04-09 17:03:12.626 CST [msp] getMspConfig -> INFO 002 Loading NodeOUs
```

<br/>

configtx.yaml 配置如下

`-printOrg Org3MSP` 中的名字要与 configtx.yaml 配置中的 `Organizations，Name` 一致。

```yaml
Organizations:
    - &Org3
        Name: Org3MSP
        ID: Org3MSP
        MSPDir: crypto-config/peerOrganizations/org3.example.com/msp
        AnchorPeers:
            - Host: peer0.org3.example.com
              Port: 7051
```
<br/>

生成的 org3.json 结构大致如下

```
{
  "groups": {},
  "mod_policy": "Admins",
  "policies": {
    "Admins": {
      "mod_policy": "Admins",
      "policy": {
        "type": 1,
        "value": {
          "identities": [
            {
              "principal": {
                "msp_identifier": "Org3MSP",
                "role": "ADMIN"
              },
              "principal_classification": "ROLE"
            }
          ],
          ... ...
      "version": "0"
    },
    "Readers": {
      ... ...
    },
    "Writers": {
      ... ...
    }
  },
  "values": {
    "MSP": {
      "mod_policy": "Admins",
      "value": {
        "config": {
          "FabricNodeOUs": {
            "Enable": true,
            "clientOUIdentifier": {
              "certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS00... ....FURS0tLS0tCg==",
              "organizational_unit_identifier": "client"
            },
            "peerOUIdentifier": {
              "certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS00... ....FURS0tLS0tCg==",
              "organizational_unit_identifier": "peer"
            }
          },
          "admins": [
            "certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS00... ....FURS0tLS0tCg==",
          ],
          "crypto_config": {
            "identity_identifier_hash_function": "SHA256",
            "signature_hash_family": "SHA2"
          },
          "name": "Org3MSP",
          "root_certs": [
            "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS00... ....FURS0tLS0tCg=="
          ],
          "tls_root_certs": [
            "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS00... ....FURS0tLS0tCg=="
          ]
        },
        "type": 0
      },
      "version": "0"
    }
  },
  "version": "0"
}
```

<br/>

### 将 orderer 的证书和密钥拷贝至 org3 的 crypto-config 目录下

```shell
cp -r ../crypto-config/ordererOrganizations crypto-config/
```

<br/>

## step3: 生成和提交新 org 的配置

通过 step 1~2，已经生成了 Org3 的证书和配置，但这仅仅是在本地文件系统，还未于区块链网络产生关联。

为 channel 新加 Org，对 Fabric 而言，是以一笔交易的形式提交的。

因此要使得这笔交易能顺利完成，需要提交 org3 的配置，获得权限认证；然后于网络中发起更新的交易



### 登录 cli 节点
```
docker exec -it cli bash
```

<br/>

### 为 cli 节点新增配置

```shell
export ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
```

<br/>

### 安装 jq 工具
`jq` 是 Linux 下命令行处理 JSON 的工具，可以对 JSON 进行过滤、格式化、修改等等操作。

```shell
apt-get -y update && apt-get -y install jq
```

<br/>

### 获取当前 channel 的配置

```shell
peer channel fetch config config_block.pb -o orderer.example.com:7050 -c mychannel --tls --cafile $ORDERER_CA
```
> 参数 `--tls` 根据区块链网络配置添加，若区块链网络配置需要 tls，没有 tls 会报 
>
> 2018-04-09 07:34:00.783 UTC [channelCmd] getNewestBlock -> ERRO 00c Received error: rpc error: code = Unavailable desc = transport is closing
> Error: rpc error: code = Unavailable desc = transport is closing 错误

<br/>

若成功，会输出

```
2018-04-09 07:34:40.358 UTC [msp] GetLocalMSP -> DEBU 001 Returning existing local MSP
2018-04-09 07:34:40.358 UTC [msp] GetDefaultSigningIdentity -> DEBU 002 Obtaining default signing identity
2018-04-09 07:34:40.363 UTC [channelCmd] InitCmdFactory -> INFO 003 Endorser and orderer connections initialized
2018-04-09 07:34:40.363 UTC [msp] GetLocalMSP -> DEBU 004 Returning existing local MSP
2018-04-09 07:34:40.363 UTC [msp] GetDefaultSigningIdentity -> DEBU 005 Obtaining default signing identity
2018-04-09 07:34:40.363 UTC [msp] GetLocalMSP -> DEBU 006 Returning existing local MSP
2018-04-09 07:34:40.363 UTC [msp] GetDefaultSigningIdentity -> DEBU 007 Obtaining default signing identity
2018-04-09 07:34:40.363 UTC [msp/identity] Sign -> DEBU 008 Sign: plaintext: 0AED060A1508021A060890AFACD60522...52D6438017E412080A020A0012020A00
2018-04-09 07:34:40.364 UTC [msp/identity] Sign -> DEBU 009 Sign: digest: DC1DEEDD462E9009BF249B5B0481D06333B699DF58764FDA9312B63144C443AE
2018-04-09 07:34:40.367 UTC [channelCmd] readBlock -> DEBU 00a Received block: 4
2018-04-09 07:34:40.368 UTC [msp] GetLocalMSP -> DEBU 00b Returning existing local MSP
2018-04-09 07:34:40.368 UTC [msp] GetDefaultSigningIdentity -> DEBU 00c Obtaining default signing identity
2018-04-09 07:34:40.368 UTC [msp] GetLocalMSP -> DEBU 00d Returning existing local MSP
2018-04-09 07:34:40.368 UTC [msp] GetDefaultSigningIdentity -> DEBU 00e Obtaining default signing identity
2018-04-09 07:34:40.368 UTC [msp/identity] Sign -> DEBU 00f Sign: plaintext: 0AED060A1508021A060890AFACD60522...2C68120C0A041A02080212041A020802
2018-04-09 07:34:40.368 UTC [msp/identity] Sign -> DEBU 010 Sign: digest: 15C3B41F571FCCAE261C280B4C3EB8A4F73DB7FA0A1E15FF11AE08072808D8A2
2018-04-09 07:34:40.371 UTC [channelCmd] readBlock -> DEBU 011 Received block: 2
2018-04-09 07:34:40.371 UTC [main] main -> INFO 012 Exiting.....
```

<br/>

### 修改原配置文件，新增 org3 配置

**1. 解码原有网络的配置文件 config_block.pb。**

`configtxlator proto_decode` 命令将 protobuf 内容转为 JSON 格式。

然后通过 jq 命令行将其中部分取出，输出至 config.json

```shell
configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config > config.json
```

config_block.pb 内容是一堆配置和证书信息，部分如下:

```
 MԀUi������
��F_z��'k�4ߝ_O �՗hy��#"��_�G�g�o��������k�z
�z
�y
�
Љ��"	mychannel�
�

OrdererMSP�-----BEGIN CERTIFICATE-----
MIICCzCCAbKgAwIBAgIQV2YjEb05t8NkbNvOF1xylDAKBggqhkjOPQQDAjBpMQsw
CQYDVQQGEwJVUzETMBEGA1UECBMKQ2FsaWZvcm5pYTEWMBQGA1UEBxMNU2FuIEZy
YW5jaXNjbzEUMBIGA1UEChMLZXhhbXBsZS5jb20xFzAVBgNVBAMTDmNhLmV4YW1w
bGUuY29tMB4XDTE4MDQwOTA2MDkxNloXDTI4MDQwNjA2MDkxNlowWDELMAkGA1UE
BhMCVVMxEzARBgNVBAgTCkNhbGlmb3JuaWExFjAUBgNVBAcTDVNhbiBGcmFuY2lz
Y28xHDAaBgNVBAMTE29yZGVyZXIuZXhhbXBsZS5jb20wWTATBgcqhkjOPQIBBggq
hkjOPQMBBwNCAAQMxQEdNLTLIU1paNblHQl9US27di5RXYu3cO0sdpjT58/l1eUP
5lNzneKx6Qg4iS/oZfJfX7mQhISKusLiyNnko00wSzAOBgNVHQ8BAf8EBAMCB4Aw
DAYDVR0TAQH/BAIwADArBgNVHSMEJDAigCAQY5DwOeZLuo8fL/jgwbf3b0OafLoE
6laY/dMS6N1mcjAKBggqhkjOPQQDAgNHADBEAiAl1yE4iRkX/OKKeNrwj3ZG/Zml
nWEF4ULvNh17oH5ZTQIgIHnp7cEZ2fSMBGE1gObW/ADBfXau2VCcLEwA2I0wWFo=
-----END CERTIFICATE-----
޷u�z��K 14ɖ8Y��"v|��s
��b�H

Application��#
Org2MSP��!
MSP�!�!�!
Org2MSP�-----BEGIN CERTIFICATE-----
... ...
... ...
```

输出的 config.json 格式类似 step2 生成的 org3.json。

<br/>

**2. 修改 config.json，新增 org3**

```shell
jq -s '.[0] * {"channel_group":{"groups":{"Application":{"groups": {"Org3MSP":.[1]}}}}}' config.json ./channel-artifacts/org3.json > modified_config.json
```


<br/>

**3. 将 config.json 和 modified_config.json 转为 protobuf 格式**
```bash
configtxlator proto_encode --input config.json --type common.Config > original_config.pb
configtxlator proto_encode --input modified_config.json --type common.Config > modified_config.pb
```

<br/>

**4. 根据 config.pb 和 modified_config.pb 计算出 org3_update.pb**
类似于 diff 操作，但是针对 protobuf 格式，因此会多出好多操作。蛋疼

```bash
configtxlator compute_update --channel_id mychannel --original original_config.pb --updated modified_config.pb > config_update.pb
```

<br/>

**5. 解码 config_update.pb 为 json，然后用 jq 修改，然后在编码为 protobuf 格式，最终输出 org3_update_in_envelope.pb**

```bash
configtxlator proto_decode --input config_update.pb  --type common.ConfigUpdate > config_update.json
echo '{"payload":{"header":{"channel_header":{"channel_id":"mychannel", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . > config_update_in_envelope.json
configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope > org3_update_in_envelope.pb
```

<br/>

### 为 Org3 新配置签名

为配置交易签名，需要 channel 中的大多数 Org 对其进行签名。

对于 mychannel 而言，已有了 org1，org2，因此新增 org3 时需要 org1、org2 都签名。

签名操作于 cli 中完成，通过更改环境变量，改变签名者的身份。

<br/>

切换至 Org1 进行签名，Org1 有两个 peer，需采用 Anchor Peer，即 `peer0.org1.example.com`

```bash
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
```

切换至 Org2 进行签名，Org2 有两个 peer，需采用 Anchor Peer，即 `peer0.org2.example.com`
```bash
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_ADDRESS=peer0.org2.example.com:7051
```

<br/>

`peer channel signconfigtx` 命令是由 admin 为配置交易（configuration transaction）签名。

> 需要分别于 org1 环境变量、org2 环境变量下分别执行一次。

```bash
peer channel signconfigtx -f org3_update_in_envelope.pb
```

若成功，以下为 Org1 签名后的输出：

```
2018-04-09 08:28:52.786 UTC [msp] GetLocalMSP -> DEBU 001 Returning existing local MSP
2018-04-09 08:28:52.786 UTC [msp] GetDefaultSigningIdentity -> DEBU 002 Obtaining default signing identity
2018-04-09 08:28:52.786 UTC [channelCmd] InitCmdFactory -> INFO 003 Endorser and orderer connections initialized
2018-04-09 08:28:52.786 UTC [msp] GetLocalMSP -> DEBU 004 Returning existing local MSP
2018-04-09 08:28:52.786 UTC [msp] GetDefaultSigningIdentity -> DEBU 005 Obtaining default signing identity
2018-04-09 08:28:52.786 UTC [msp] GetLocalMSP -> DEBU 006 Returning existing local MSP
2018-04-09 08:28:52.786 UTC [msp] GetDefaultSigningIdentity -> DEBU 007 Obtaining default signing identity
2018-04-09 08:28:52.786 UTC [msp/identity] Sign -> DEBU 008 Sign: plaintext: 0AB6060A074F7267314D535012AA062D...72697465727312002A0641646D696E73
2018-04-09 08:28:52.787 UTC [msp/identity] Sign -> DEBU 009 Sign: digest: 7CC3CB504C7AC5588E1C347305262066757B45E8F99F39D18836B4A60EB22901
2018-04-09 08:28:52.787 UTC [msp] GetLocalMSP -> DEBU 00a Returning existing local MSP
2018-04-09 08:28:52.787 UTC [msp] GetDefaultSigningIdentity -> DEBU 00b Obtaining default signing identity
2018-04-09 08:28:52.787 UTC [msp] GetLocalMSP -> DEBU 00c Returning existing local MSP
2018-04-09 08:28:52.787 UTC [msp] GetDefaultSigningIdentity -> DEBU 00d Obtaining default signing identity
2018-04-09 08:28:52.787 UTC [msp/identity] Sign -> DEBU 00e Sign: plaintext: 0AED060A1508021A0608C4C8ACD60522...DBB67FA8B0E04B91898888F898CA2EF5
2018-04-09 08:28:52.787 UTC [msp/identity] Sign -> DEBU 00f Sign: digest: 8FCE6B4E8A5A9E89D1CE6F624D1CA0AE04EEC1448ACC3B67F294241DB7A96960
2018-04-09 08:28:52.787 UTC [main] main -> INFO 010 Exiting.....
```

<br/>

### 提交签名后的配置交易至 orderer

```shell
export ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
peer channel update -f org3_update_in_envelope.pb -c mychannel -o orderer.example.com:7050 --tls --cafile $ORDERER_CA
```

<br/>

### 验证 orderer 是否完成排序，并于 peer 入链

于宿主机下，查看 docker 内输出

```shell
docker logs -ft peer0.org1.example.com
docker logs -ft peer0.org2.example.com
```

若入链，可以看到以下输出：

```
2018-04-09T09:06:21.465870592Z 2018-04-09 09:06:21.465 UTC [kvledger] CommitWithPvtData -> INFO 03d Channel [mychannel]: Committed block [5] with 1 transaction(s)
```

输出显示，当前提交的块号是 5。

块 0 是创世块；1~2 是一些初始化；3~4 是实例化与调用 chaincode ，更新配置。

<br/>


## step4: 将新 org 添加入 channel

### 启动新 org 集群

Org3 集群包含一个 org3cli 和 2 个 peer

```shell
docker-compose -f docker-compose-org3.yaml up -d
```

输出

```
Creating volume "net_peer0.org3.example.com" with default driver
Creating volume "net_peer1.org3.example.com" with default driver
WARNING: Found orphan containers (cli, peer1.org1.example.com, peer1.org2.example.com, peer0.org2.example.com, peer0.org1.example.com, orderer.example.com) for this project. If you removed or renamed this service in your compose file, youCreating peer1.org3.example.com ... done
Creating Org3cli ... done
Creating peer1.org3.example.com ...
Creating Org3cli ...
```

`docker ps` 查看新启动的镜像，比之前会多出以下三个

```
CONTAINER ID        IMAGE                                                                                                  COMMAND                  CREATED             STATUS              PORTS                                              NAMES
7b80ce329182        hyperledger/fabric-tools:latest                                                                        "/bin/bash"              35 seconds ago      Up 33 seconds                                                          Org3cli
f7990009b206        hyperledger/fabric-peer:latest                                                                         "peer node start"        35 seconds ago      Up 34 seconds       0.0.0.0:12051->7051/tcp, 0.0.0.0:12053->7053/tcp   peer1.org3.example.com
9bff0310d237        hyperledger/fabric-peer:latest                                                                         "peer node start"        35 seconds ago      Up 34 seconds       0.0.0.0:11051->7051/tcp, 0.0.0.0:11053->7053/tcp   peer0.org3.example.com
```

docker-compose-org3.yaml 配置如下：

```yaml
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

version: '2'

volumes:
  peer0.org3.example.com:
  peer1.org3.example.com:

networks:
  byfn:

services:

  peer0.org3.example.com:
    container_name: peer0.org3.example.com
    extends:
      file: base/peer-base.yaml
      service: peer-base
    environment:
      - CORE_PEER_ID=peer0.org3.example.com
      - CORE_PEER_ADDRESS=peer0.org3.example.com:7051
      - CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer0.org3.example.com:7051
      - CORE_PEER_LOCALMSPID=Org3MSP
    volumes:
        - /var/run/:/host/var/run/
        - ./org3-artifacts/crypto-config/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/msp:/etc/hyperledger/fabric/msp
        - ./org3-artifacts/crypto-config/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls:/etc/hyperledger/fabric/tls
        - peer0.org3.example.com:/var/hyperledger/production
    ports:
      - 11051:7051
      - 11053:7053
    networks:
      - byfn

  peer1.org3.example.com:
    container_name: peer1.org3.example.com
    extends:
      file: base/peer-base.yaml
      service: peer-base
    environment:
      - CORE_PEER_ID=peer1.org3.example.com
      - CORE_PEER_ADDRESS=peer1.org3.example.com:7051
      - CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer1.org3.example.com:7051
      - CORE_PEER_GOSSIP_BOOTSTRAP=peer0.org3.example.com:7051
      - CORE_PEER_LOCALMSPID=Org3MSP
    volumes:
        - /var/run/:/host/var/run/
        - ./org3-artifacts/crypto-config/peerOrganizations/org3.example.com/peers/peer1.org3.example.com/msp:/etc/hyperledger/fabric/msp
        - ./org3-artifacts/crypto-config/peerOrganizations/org3.example.com/peers/peer1.org3.example.com/tls:/etc/hyperledger/fabric/tls
        - peer1.org3.example.com:/var/hyperledger/production
    ports:
      - 12051:7051
      - 12053:7053
    networks:
      - byfn


  Org3cli:
    container_name: Org3cli
    image: hyperledger/fabric-tools:$IMAGE_TAG
    tty: true
    stdin_open: true
    environment:
      - GOPATH=/opt/gopath
      - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
      #- CORE_LOGGING_LEVEL=INFO
      - CORE_LOGGING_LEVEL=DEBUG
      - CORE_PEER_ID=Org3cli
      - CORE_PEER_ADDRESS=peer0.org3.example.com:7051
      - CORE_PEER_LOCALMSPID=Org3MSP
      - CORE_PEER_TLS_ENABLED=true
      - CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/server.crt
      - CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/server.key
      - CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt
      - CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp
    working_dir: /opt/gopath/src/github.com/hyperledger/fabric/peer
    command: /bin/bash
    volumes:
        - /var/run/:/host/var/run/
        - ./../chaincode/:/opt/gopath/src/github.com/chaincode
        - ./org3-artifacts/crypto-config:/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/
        - ./scripts:/opt/gopath/src/github.com/hyperledger/fabric/peer/scripts/
    depends_on:
      - peer0.org3.example.com
      - peer1.org3.example.com
    networks:
      - byfn
```

<br/>

### 登录新 org 集群，获取当前 channel 配置

**1. 登录 Org3Cli**
```shell
docker exec -it Org3cli bash
```

<br/>

**2. 添加环境变量**

```shell
export ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export CHANNEL_NAME=mychannel
```

<br/>

**3. 获取当前 channel 的配置**

Org3Cli 从 orderer 中获取 channel 创世块配置

```shell
peer channel fetch 0 mychannel.block -o orderer.example.com:7050 -c $CHANNEL_NAME --tls --cafile $ORDERER_CA
```

输出：
```
2018-04-09 09:40:57.475 UTC [msp] GetLocalMSP -> DEBU 001 Returning existing local MSP
2018-04-09 09:40:57.475 UTC [msp] GetDefaultSigningIdentity -> DEBU 002 Obtaining default signing identity
2018-04-09 09:40:57.479 UTC [channelCmd] InitCmdFactory -> INFO 003 Endorser and orderer connections initialized
2018-04-09 09:40:57.479 UTC [msp] GetLocalMSP -> DEBU 004 Returning existing local MSP
2018-04-09 09:40:57.479 UTC [msp] GetDefaultSigningIdentity -> DEBU 005 Obtaining default signing identity
2018-04-09 09:40:57.480 UTC [msp] GetLocalMSP -> DEBU 006 Returning existing local MSP
2018-04-09 09:40:57.480 UTC [msp] GetDefaultSigningIdentity -> DEBU 007 Obtaining default signing identity
2018-04-09 09:40:57.480 UTC [msp/identity] Sign -> DEBU 008 Sign: plaintext: 0AED060A1508021A0608A9EAACD60522...460550DD7A5812080A021A0012021A00
2018-04-09 09:40:57.480 UTC [msp/identity] Sign -> DEBU 009 Sign: digest: 4A8C7BC724EEDA0B6D132395D371938BA7328D8E7F8C49B34F765FE3859AC106
2018-04-09 09:40:57.485 UTC [channelCmd] readBlock -> DEBU 00a Received block: 0
2018-04-09 09:40:57.485 UTC [main] main -> INFO 00b Exiting.....
```

<br/>

### 将 Org 所有 Peer 加入 channel

Org3 下拥有 2 个 Peer，peer0 和 peer1，其下所有 peer 均需要执行加入 channel 操作。



切换至 Peer0，即 peer0.org3.example.com，将其加入 channel

```bash
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt
export CORE_PEER_ADDRESS=peer0.org3.example.com:7051
```

切换至 Peer1，即 peer1.org3.example.com，将其加入 channel

```shell
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.example.com/peers/peer1.org3.example.com/tls/ca.crt
export CORE_PEER_ADDRESS=peer1.org3.example.com:7051
```



> 需要分别于 peer0 环境变量、peer1 环境变量下分别执行一次。

```shell
peer channel join -b mychannel.block
```

peer0 与 peer1 输出差不多，如下：

```
2018-04-09 09:43:22.968 UTC [msp] GetLocalMSP -> DEBU 001 Returning existing local MSP
2018-04-09 09:43:22.968 UTC [msp] GetDefaultSigningIdentity -> DEBU 002 Obtaining default signing identity
2018-04-09 09:43:22.972 UTC [channelCmd] InitCmdFactory -> INFO 003 Endorser and orderer connections initialized
2018-04-09 09:43:22.974 UTC [msp/identity] Sign -> DEBU 004 Sign: plaintext: 0AB4070A5C08011A0C08BAEBACD60510...21BD37B89AAE1A080A000A000A000A00
2018-04-09 09:43:22.974 UTC [msp/identity] Sign -> DEBU 005 Sign: digest: 00E3992EDAC99AC1FCAD1181FFE1993435C02EEAF8A5311CBEB935A8A0F9A68A
2018-04-09 09:43:23.007 UTC [channelCmd] executeJoin -> INFO 006 Successfully submitted proposal to join channel
2018-04-09 09:43:23.008 UTC [main] main -> INFO 007 Exiting.....
```

<br/>

## step5: 升级chaincode和背书策略

最后一步，是增加 chaincode 版本号并更新背书策略。



### 为 Org3 安装 2.0 版本的 chaincode

当前 Org1 和 Org2 的 chaincode 版本号是 1，Org3 需要更新此版本的 chaincode，因此为 Org3 直接安装版本为 2 的 chaincode，省得先安装再升级。



```shell
peer chaincode install -n mycc -v 2.0 -p github.com/chaincode/chaincode_example02/go/
```

输出如下：

```
2018-04-09 10:24:46.493 UTC [msp] GetLocalMSP -> DEBU 001 Returning existing local MSP
2018-04-09 10:24:46.493 UTC [msp] GetDefaultSigningIdentity -> DEBU 002 Obtaining default signing identity
2018-04-09 10:24:46.493 UTC [chaincodeCmd] checkChaincodeCmdParams -> INFO 003 Using default escc
2018-04-09 10:24:46.493 UTC [chaincodeCmd] checkChaincodeCmdParams -> INFO 004 Using default vscc
2018-04-09 10:24:46.493 UTC [chaincodeCmd] getChaincodeSpec -> DEBU 005 java chaincode enabled
2018-04-09 10:24:46.543 UTC [golang-platform] getCodeFromFS -> DEBU 006 getCodeFromFS github.com/chaincode/chaincode_example02/go/
2018-04-09 10:24:46.661 UTC [golang-platform] func1 -> DEBU 007 Discarding GOROOT package fmt
2018-04-09 10:24:46.661 UTC [golang-platform] func1 -> DEBU 008 Discarding provided package github.com/hyperledger/fabric/core/chaincode/shim
2018-04-09 10:24:46.662 UTC [golang-platform] func1 -> DEBU 009 Discarding provided package github.com/hyperledger/fabric/protos/peer
2018-04-09 10:24:46.662 UTC [golang-platform] func1 -> DEBU 00a Discarding GOROOT package strconv
2018-04-09 10:24:46.662 UTC [golang-platform] GetDeploymentPayload -> DEBU 00b done
2018-04-09 10:24:46.662 UTC [container] WriteFileToPackage -> DEBU 00c Writing file to tarball: src/github.com/chaincode/chaincode_example02/go/chaincode_example02.go
2018-04-09 10:24:46.664 UTC [msp/identity] Sign -> DEBU 00d Sign: plaintext: 0AB4070A5C08031A0C08EEFEACD60510...CAF857000000FFFF354C5FFC001C0000
2018-04-09 10:24:46.664 UTC [msp/identity] Sign -> DEBU 00e Sign: digest: 0E27BFDD36A93200D1519FFACF65F1813491E3FAADD90AD5227245C6A4A1445A
2018-04-09 10:24:46.667 UTC [chaincodeCmd] install -> DEBU 00f Installed remotely response:<status:200 payload:"OK" >
2018-04-09 10:24:46.667 UTC [main] main -> INFO 010 Exiting.....
```

<br/>

### 为 Org1 的 peer0、Org2 的 peer0 安装 2.0 版本 chaincode

登录原 cli，对 org1，org2 进行管理。

```shell
docker exec -it cli bash
```

<br/>

切换至 Org1 进行环境

```bash
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
```

切换至 Org2 进行环境

```bash
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_ADDRESS=peer0.org2.example.com:7051
```



> 需执行两次，分别于 org1，org2 环境下

```shell
peer chaincode install -n mycc -v 2.0 -p github.com/chaincode/chaincode_example02/go
```

<br/>

### 升级背书策略

升级背书策略，`-v 2.0` 指明版本号，`-P "OR ('Org1MSP.peer','Org2MSP.peer','Org3MSP.peer')"` 指明新的背书策略（添加了 Org3）。

```shell
peer chaincode upgrade -o orderer.example.com:7050 --tls $CORE_PEER_TLS_ENABLED --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n mycc -v 2.0 -c '{"Args":["init","a","90","b","210"]}' -P "OR ('Org1MSP.peer','Org2MSP.peer','Org3MSP.peer')"
```

若成功，输出如下：

```
2018-04-09 10:45:30.132 UTC [msp] GetLocalMSP -> DEBU 001 Returning existing local MSP
2018-04-09 10:45:30.132 UTC [msp] GetDefaultSigningIdentity -> DEBU 002 Obtaining default signing identity
2018-04-09 10:45:30.136 UTC [chaincodeCmd] checkChaincodeCmdParams -> INFO 003 Using default escc
2018-04-09 10:45:30.136 UTC [chaincodeCmd] checkChaincodeCmdParams -> INFO 004 Using default vscc
2018-04-09 10:45:30.136 UTC [chaincodeCmd] getChaincodeSpec -> DEBU 005 java chaincode enabled
2018-04-09 10:45:30.136 UTC [chaincodeCmd] upgrade -> DEBU 006 Get upgrade proposal for chaincode <name:"mycc" version:"2.0" >
2018-04-09 10:45:30.136 UTC [msp/identity] Sign -> DEBU 007 Sign: plaintext: 0AC2070A6608031A0B08CA88ADD60510...535010030A04657363630A0476736363
2018-04-09 10:45:30.137 UTC [msp/identity] Sign -> DEBU 008 Sign: digest: 4C4F7827359FBEA37BF97D2BAD15FC9762360DF414BF277A22869CBF7A605DB8
2018-04-09 10:45:39.103 UTC [chaincodeCmd] upgrade -> DEBU 009 endorse upgrade proposal, get response <status:200 message:"OK" payload:"\n\004mycc\022\0032.0\032\004escc\"\004vscc*?\022\020\022\016\010\001\022\002\010\000\022\002\010\001\022\002\010\002\032\r\022\013\n\007Org1MSP\020\003\032\r\022\013\n\007Org2MSP\020\003\032\r\022\013\n\007Org3MSP\020\0032D\n \222G\373\202N!\320\207\017\376y<\360`$\346^\206\361\340\345\213d\351\014[\031On74\000\022 g\357,\324!\221P`u\035X\006\327\257\037\324\334\003\003\251\2628\321\345\262$\360\r\351\220^\\: \235\322J\005\214V\273\257\340\244\273$y\325\215iP\365\211\266'\267<p)\340\020\364`\247\307\323B?\022\020\022\016\010\001\022\002\010\000\022\002\010\001\022\002\010\002\032\r\022\013\n\007Org1MSP\020\001\032\r\022\013\n\007Org2MSP\020\001\032\r\022\013\n\007Org3MSP\020\001" >
2018-04-09 10:45:39.103 UTC [msp/identity] Sign -> DEBU 00a Sign: plaintext: 0AC2070A6608031A0B08CA88ADD60510...430D37D0D4AE72A17EB35E2DA134DA99
2018-04-09 10:45:39.103 UTC [msp/identity] Sign -> DEBU 00b Sign: digest: 23A320F7C7E644FBA5D097D472246F47FD33B7C6A077AFE50F60B36E8ECDC7DC
2018-04-09 10:45:39.103 UTC [chaincodeCmd] upgrade -> DEBU 00c Get Signed envelope
2018-04-09 10:45:39.104 UTC [chaincodeCmd] chaincodeUpgrade -> DEBU 00d Send signed envelope to orderer
2018-04-09 10:45:39.105 UTC [main] main -> INFO 00e Exiting.....
```

<br/>

`peer chaincode upgrade` 命令将为区块链新增一个块，可以在 peer 的输出中查看

```shell
docker logs -ft peer0.org1.example.com
```

可以看到，块号已经升至 6.

```
2018-04-09T10:45:41.113103936Z 2018-04-09 10:45:41.112 UTC [committer/txvalidator] validateTx -> INFO 203 Find chaincode upgrade transaction for chaincode mycc on channel mychannel with new version 2.0
2018-04-09T10:45:41.113566483Z 2018-04-09 10:45:41.113 UTC [cceventmgmt] HandleStateUpdates -> INFO 204 Channel [mychannel]: Handling LSCC state update for chaincode [mycc]
2018-04-09T10:45:41.115440650Z 2018-04-09 10:45:41.115 UTC [kvledger] CommitWithPvtData -> INFO 205 Channel [mychannel]: Committed block [6] with 1 transaction(s)
```

<br/>

## step6: 测试是否成功

**发起一笔查询**

```shell
peer chaincode query -C $CHANNEL_NAME -n mycc -c '{"Args":["query","a"]}'
```

得到以下结果，`Query Result: 90`

```
2018-04-09 10:46:56.063 UTC [msp] GetLocalMSP -> DEBU 001 Returning existing local MSP
2018-04-09 10:46:56.063 UTC [msp] GetDefaultSigningIdentity -> DEBU 002 Obtaining default signing identity
2018-04-09 10:46:56.063 UTC [chaincodeCmd] checkChaincodeCmdParams -> INFO 003 Using default escc
2018-04-09 10:46:56.063 UTC [chaincodeCmd] checkChaincodeCmdParams -> INFO 004 Using default vscc
2018-04-09 10:46:56.063 UTC [chaincodeCmd] getChaincodeSpec -> DEBU 005 java chaincode enabled
2018-04-09 10:46:56.064 UTC [msp/identity] Sign -> DEBU 006 Sign: plaintext: 0AC2070A6608031A0B08A089ADD60510...6D7963631A0A0A0571756572790A0161
2018-04-09 10:46:56.064 UTC [msp/identity] Sign -> DEBU 007 Sign: digest: 5C801C9C2085286736CEEDB46B6E7FDBB83C4B6C472E81BDF2A31E07FE76DAB5
Query Result: 90
2018-04-09 10:46:56.072 UTC [main] main -> INFO 008 Exiting.....
```

然后，发起一笔调用，调用是将 `a` 转 `10` 至 `b`

```shell
peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mycc -c '{"Args":["invoke","a","b","10"]}'
```

输出如下：

```
2018-04-09 10:47:21.151 UTC [msp] GetLocalMSP -> DEBU 001 Returning existing local MSP
2018-04-09 10:47:21.151 UTC [msp] GetDefaultSigningIdentity -> DEBU 002 Obtaining default signing identity
2018-04-09 10:47:21.155 UTC [chaincodeCmd] checkChaincodeCmdParams -> INFO 003 Using default escc
2018-04-09 10:47:21.155 UTC [chaincodeCmd] checkChaincodeCmdParams -> INFO 004 Using default vscc
2018-04-09 10:47:21.155 UTC [chaincodeCmd] getChaincodeSpec -> DEBU 005 java chaincode enabled
2018-04-09 10:47:21.155 UTC [msp/identity] Sign -> DEBU 006 Sign: plaintext: 0AC2070A6608031A0B08B989ADD60510...696E766F6B650A01610A01620A023130
2018-04-09 10:47:21.155 UTC [msp/identity] Sign -> DEBU 007 Sign: digest: 69ABEEFD6EC7327C6C6FA36F4302965F2C8DC69AD388634A5737726A6C2E8EE8
2018-04-09 10:47:21.163 UTC [msp/identity] Sign -> DEBU 008 Sign: plaintext: 0AC2070A6608031A0B08B989ADD60510...0EEC6E3A64572217C0ECC4FA2AF449FE
2018-04-09 10:47:21.163 UTC [msp/identity] Sign -> DEBU 009 Sign: digest: E4191E37ED4A0D742CF3C969E348350BA3BC68292A474B64D7B1F71104E5DC59
2018-04-09 10:47:21.165 UTC [chaincodeCmd] chaincodeInvokeOrQuery -> DEBU 00a ESCC invoke result: version:1 response:<status:200 message:"OK" > payload:"\n \240\361-\006{d\325!\321\017\323Y\254l\303\351\222W\226\275T\255\002\333\260\201\350\230Z<\234\320\022Y\nE\022\024\n\004lscc\022\014\n\n\n\004mycc\022\002\010\006\022-\n\004mycc\022%\n\007\n\001a\022\002\010\006\n\007\n\001b\022\002\010\006\032\007\n\001a\032\00280\032\010\n\001b\032\003220\032\003\010\310\001\"\013\022\004mycc\032\0032.0" endorsement:<endorser:"\n\007Org2MSP\022\246\006-----BEGIN CERTIFICATE-----\nMIICJzCCAc6gAwIBAgIQSt8xNetxpTvWnh7QS9Z9ojAKBggqhkjOPQQDAjBzMQsw\nCQYDVQQGEwJVUzETMBEGA1UECBMKQ2FsaWZvcm5pYTEWMBQGA1UEBxMNU2FuIEZy\nYW5jaXNjbzEZMBcGA1UEChMQb3JnMi5leGFtcGxlLmNvbTEcMBoGA1UEAxMTY2Eu\nb3JnMi5leGFtcGxlLmNvbTAeFw0xODA0MDkwODUzNDRaFw0yODA0MDYwODUzNDRa\nMGoxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpDYWxpZm9ybmlhMRYwFAYDVQQHEw1T\nYW4gRnJhbmNpc2NvMQ0wCwYDVQQLEwRwZWVyMR8wHQYDVQQDExZwZWVyMC5vcmcy\nLmV4YW1wbGUuY29tMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEK3WWG/HkydkW\nZ8tjS+WEfEKbn7+O82akp5ckzEKsbN6ucK3rCCM9hUGizEikSXSnxGQ/thB1vkPU\nEZtwjlL+w6NNMEswDgYDVR0PAQH/BAQDAgeAMAwGA1UdEwEB/wQCMAAwKwYDVR0j\nBCQwIoAgLw9SFcdoizgo4xv+OMJoM5Ev5gnvDSXI+0AoQGjfXmowCgYIKoZIzj0E\nAwIDRwAwRAIgcsLdt9YS3xkyZ3w+7CPepULC9ScpvPjgbzhQJdWGt34CIHa1fDJp\nSpfEYkXxZVpKsAFDP/+TZ1CR/BipvZj6Ucvc\n-----END CERTIFICATE-----\n" signature:"0E\002!\000\340X\274\360\215\367\304\032\261e\351\225\026C9\262\177\037I\327\000.}\317.\016\245\223\026\374h\211\002 1\202\362\344IU\010\250=\364A\320\235\n\\H\016\354n:dW\"\027\300\354\304\372*\364I\376" >
2018-04-09 10:47:21.165 UTC [chaincodeCmd] chaincodeInvokeOrQuery -> INFO 00b Chaincode invoke successful. result: status:200
2018-04-09 10:47:21.165 UTC [main] main -> INFO 00c Exiting.....
```

`peer chaincode invoke` 会生成一个新块，同上，可以通过 `docker logs -ft peer0.org1.example.com` 查看，此时块号将变为 7。

再次调用查询命令`peer chaincode query -C $CHANNEL_NAME -n mycc -c '{"Args":["query","a"]}'`, 得到以下输出。可以看到 `Query Result: 80`，说明调用已经成功。

```
2018-04-09 10:47:40.210 UTC [msp] GetLocalMSP -> DEBU 001 Returning existing local MSP
2018-04-09 10:47:40.210 UTC [msp] GetDefaultSigningIdentity -> DEBU 002 Obtaining default signing identity
2018-04-09 10:47:40.210 UTC [chaincodeCmd] checkChaincodeCmdParams -> INFO 003 Using default escc
2018-04-09 10:47:40.210 UTC [chaincodeCmd] checkChaincodeCmdParams -> INFO 004 Using default vscc
2018-04-09 10:47:40.210 UTC [chaincodeCmd] getChaincodeSpec -> DEBU 005 java chaincode enabled
2018-04-09 10:47:40.211 UTC [msp/identity] Sign -> DEBU 006 Sign: plaintext: 0AC2070A6608031A0B08CC89ADD60510...6D7963631A0A0A0571756572790A0161
2018-04-09 10:47:40.211 UTC [msp/identity] Sign -> DEBU 007 Sign: digest: E0206FCC932E0928EBB8D980C0A485AB34FD3F31CCD01F433606DD76F57C5854
Query Result: 80
2018-04-09 10:47:40.219 UTC [main] main -> INFO 008 Exiting.....
```

<br/>

# 参考资料

[1] Hyperledger Fabric 官方手册， http://hyperledger-fabric.readthedocs.io/en/latest/channel_update_tutorial.html
[2] Fabric学习笔记(八) - cli动态添加Org, 作者 mumubin，https://segmentfault.com/a/1190000013521785