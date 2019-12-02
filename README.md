# SMEasyAudioEngine
基于AUGraph的简单音频处理工具
使用类似AVFoundation 里的AVAudioEngine
但是能够定制AVAudioNode，实现想要的效果

SMEasyAudioEngine         音频渲染管理工具，用于添加、连接节点。启动暂停渲染，内部管理AUGraph

SMEasyAudioNode           节点基类

SMEasyAudioSplitterNode   分路节点 一路输入 二路输出

SMEasyAudioRecordNode     录制节点

SMEasyAudioPlayerNode     播放节点

SMEasyAudioOutputNode     音频流输出节点基类

SMEasyAudioMixerNode      多路合并接点  多路输入，一路输出

SMEasyAudioIONode         IO节点 实现采集和播放的节点，比较特殊

SMEasyAudioGenericOutputNode 音频输出节点，比较特殊可以实现离线音频渲染合唱

SMEasyAudioFloatToInt16OutPutNode  float转 short音频流输出节点

SMEasyAudioErrorCheck     错误检测

SMEasyAudioConvertNode    音频格式转换节点，可以实现重采样，设置输入输出数据流采样率

SMEasyAudioConstants      定义渲染的数据格式
