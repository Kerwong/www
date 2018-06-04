---
title: Introduction of Machine Learning
comments: true
date: 2016-12-19 09:59:01
tags:
- Machine Learning
---

# 关于机器学习研究的一些讨论

南大周志华讲座
<http://cs.nju.edu.cn/zhouzh>

大数据 -> 大价值

数据


学习算法

- 互联网搜索
- 生物特征识别
- 汽车自动驾驶

# 常用技术
- 决策树
  - C4.5
- 神经网络
  - BP
  - SOM
- 近邻分类器
  - 1NN
  - kNN
- 贝叶斯分类器
  - Naive Bayes Classifier
  - TAN
  - AODE
  - Bayesian network
$$P(H|X) = frac(P(X|H)P(H))(P(X))$$
- 大间隔分类器
- 集成学习 Ensemble learning
  - AdaBoost
  - Bagging
  - Random foreest
  - Random Subspace

# 技术的选择
> 具体问题，具体分析

# 机器学习应用场景
不适用于：
- 特征信息不充分
  - 重要特征信息没有获得
- 样本信息不充分
  - 数据样本太少

深度学习适用于
- 数据的“初试表示”与“合适表示”相距较远，例如图像识别

# 计算学习理论

# 深度学习
  神经网络

网络深度

提升模型复杂度 -> 提升学习能力
增加隐层神经元数目（宽度）
增加隐层数据（深度）

增加深度比宽度更有效

提升模型复杂度 -> 增加过拟合风险，增加计算开销
过拟合风险：使用大量训练数据
计算开销：使用强力计算设备

> 误差梯度在多隐层内传播时，往往会发散而不能收敛到稳定状态，难以直接用经典 BP 算法训练


传统做法 -> 特征工程（人工设计特征） -> 学习分类
深度学习 -> 学习特征（表示学习） -> 学习分类

# 典型问题
动态分布变化时的模型变化
样本类别可增
样本属性变化
评价目标变化

# 对于未来
开放环境机器学习，robust
有效利用强力计算设备


强化学习？
迁移学习？