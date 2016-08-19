/**
 * Created by zhouzhanglin on 16/8/19.
 */
package data {
public class AnimationData {
    public var name:String;//动画名称
    public var playTimes:int=1;//播放次数，0为循环播放
    public var duration:int =1; // 动画帧长度 (可选属性 默认: 1)
    public var keyDatas:Vector.<AnimKeyData>;
    public var boneDatas:Vector.<AnimKeyData>;
    public var slotDatas:Vector.<AnimKeyData>;
    public var ffdDatas:Vector.<AnimKeyData>;
}
}
