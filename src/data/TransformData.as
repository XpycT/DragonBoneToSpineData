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
    public function Add(transform:TransformData):TransformData{
        x+=transform.x;
        y+=transform.y;
        rotate+=transform.rotate;
        scx+=transform.scx;
        scy+=transform.scy;
        return this;
    }
}
}
