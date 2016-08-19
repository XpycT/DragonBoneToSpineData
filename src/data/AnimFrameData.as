/**
 * Created by zhouzhanglin on 16/8/19.
 */
package data {
import flash.geom.Point;

public class AnimFrameData {
    public var duration:int = 1;
    public var curve:Vector<Number>;
    public var tweenEasing:Number = NaN;
    public var displayIndex:int=0;
    public var z:Number;
    public var transformData:TransformData ;
    public var color:ColorData;

    //网格动画
    public var offset:int=0;//顶点坐标索引偏移
    public var vertices:Vector.<Point>;//顶点位置,顶点坐标相对位移
}
}
