/**
 * Created by zhouzhanglin on 16/8/19.
 */
package data {
public class AnimSubData {
    public var name:String;//slotname , bone name
    public var slot:String;//如果有slot，就用slot
    public var duration:int = 1;
    public var scale:Number=1;
    public var offset:Number=0;
    public var frameDatas:Vector.<AnimFrameData>;
}
}
