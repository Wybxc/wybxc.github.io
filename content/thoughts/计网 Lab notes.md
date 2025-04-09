---
date: 2024-04-21
---

## AlphaRTC

- 环境配置：~~pull form docker~~
- 测试数据：仓库提供的 examples

似乎不能发送太大的文件（1920x1080x24fps 的视频直接失败）

接收到的音视频数据大小明显大于 ffmpeg 生成的 YUV 和 wav（实际上是时长问题）

sender 在连接断开之前会一直重复视频流，receiver 在 sender 未连接时不会输出，所以 receiver 的工作时间可以比 sender 长

receiver 的输出虽然默认配置文件的拓展名是yuv但**实际上是 y4m 格式**（所以不能被像素数量整除，因为有文件头）[链接](https://github.com/OpenNetLab/AlphaRTC/blob/957290e5ea66b1c457f03be2097cae2bc8208c63/examples/peerconnection/serverless/conductor.cc#L178)

### build docker image

原仓库使用 ubuntu 18.04，与新版gn不兼容，所以修改`dockers/Dockerfile.compile`，使用 ubuntu 20.04

## Vmaf

- 安装：arch 大法

命令：

```shell
vmaf -r test.y4m -d example/outvideo.yuv
```

## 测试数据

### YUV 数据格式

提取音视频流：

```shell
ffmpeg -i kara.mkv -vf "fps=24,scale=640:360:flags=lanczos,format=yuv420p" -ss 19:46 -t 20 -c:v rawvideo -pix_fmt yuv420p kara.yuv -vn -acodec pcm_s16le -ar 44100 -ac 2 kara.wav
```

1. `-i kara.mkv`: 这部分指定了输入文件的名称，即 `kara.mkv`。
2. `-vf "fps=24,scale=640:360:flags=lanczos,format=yuv420p"`: 这是视频过滤器选项。它包括以下几个部分：
    - `fps=24`: 设置输出视频的帧率为 24 帧每秒。
    - `scale=640:360`: 调整视频的分辨率为 640x360 像素。
    - `flags=lanczos`: 使用 Lanczos 算法进行缩放。
    - `format=yuv420p`: 设置输出视频的像素格式为 YUV420P。
3. `-c:v rawvideo -pix_fmt yuv420p kara.yuv`: 这部分指定了输出视频文件的名称为 `kara.yuv`，并使用原始视频编码（rawvideo）和 YUV420P 像素格式。
4. `-vn -acodec pcm_s16le -ar 44100 -ac 2 kara.wav`: 这是音频选项，用于生成音频文件 `kara.wav`：
    - `-vn`: 禁用视频流。
    - `-acodec pcm_s16le`: 使用 16 位有符号整数的 PCM 编码。
    - `-ar 44100`: 设置音频采样率为 44.1 kHz。
    - `-ac 2`: 设置音频通道数为 2（立体声）。

从 YUV 编码视频：

```shell
ffmpeg -f rawvideo -pix_fmt yuv420p -s 320x240 -r 10 -i outv.yuv -y outv.y4m
```

y4m 可以用 ffplay 播放