/**
 * Created by zhouzhanglin on 16/8/19.
 */
package data {
public class ArmatureData {
    public var name:String;
    public var isGlobal:int = 1 ;
    public var frameRate:int = 24 ;
    public var boneDatas:Vector.<BoneData>;
    public var slotDatas:Vector.<SlotData>;
    public var animDatas:Vector.<AnimationData>;
    public var skinDatas:Vector.<SkinData>;
    public var ikDatas:Vector.<IKData>;
}
}
