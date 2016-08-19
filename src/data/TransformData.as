/**
 * Created by zhouzhanglin on 16/8/19.
 */
package data {
public class TransformData {
    public var x:Number = 0;
    public var y:Number = 0;
    public var rotate:Number = 0;
    public var scx:Number = 1;
    public var scy:Number = 1;
    public function Add(data:TransformData):TransformData{
        x+=data.x;
        y+=data.y;
        rotate+=data.rotate;
        scx+=data.scx;
        scy+=data.scy;
        return this;
    }
}
}
