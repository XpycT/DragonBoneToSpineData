/**
 * Created by zhouzhanglin on 16/8/19.
 */
package data {
import flash.geom.Point;

public class SkinSlotDisplayData {

    public var textureName:String;
    public var type:String = "image";//armature,mesh
    public var pivot:Point = new Point(0.5,0.5);
    public var transform:TransformData;
    public var color:ColorData;

        //网格变化
    public var vertices:Vector.<Point>;
    public var uvs:Vector.<Point>;
    public var triangles:Vector.<int>;
    public var boneIndex:Vector.<int>;
    public var vertexIndex:Vector.<int>;
    public var bonePose:Vector.<Number>;
    public var weights:Vector.<Number>;//[顶点索引, 骨骼索引, 权重, ...]

}
}
