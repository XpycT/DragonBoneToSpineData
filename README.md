#DragonBoneToSpineData
将DragonBone导出的数据，转化成spine对应格式

#使用方法
下载该项目，在release文件夹中找到相应的运行程序，里面有mac和windows两个，选择你合适的

将DragonBone导出的文件夹，直接拖到窗体相应区域，然后点击convert按钮。如果成功会有提示，成功后会在同目录创建一个xxx_spine的目录，点击窗体上的路径，可以直接跳到该目录
![](http://git.oschina.net/uploads/images/2016/0828/210846_550b085d_12360.jpeg "")

#注意事项
动画嵌套不支持(因为Spine没此功能)，IK动画没做测试<br/>
当前只在Unity中测试过转换后的文件。

#说明
release文件中，“DragonBoneToSpine_mac.app.zip”是mac上的绿色版本 ,  “DragonBoneToSpine_win.zip”是windows上的绿色版本 , "DragonBoneToSpine.air"为通用版本，需要安装Flash AIR环境<br/>
如果你要使用DragonBone转Unity动画，可以访问此处[DragonBoneToUnity](http://git.oschina.net/bingheliefeng/DragonBone_Unity)

#change list v1.0.5
fix: 当蒙皮动画和变形动画同时使用时，转换出错

#Change list v1.0.4
fix: 转换顶点动画时，offset为奇数时会转换错误
