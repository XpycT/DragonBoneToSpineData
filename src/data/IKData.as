/**
 * Created by zhouzhanglin on 16/8/19.
 */
package data {

public class IKData{
    public var name:String;//ik名称
    public var bone:String;//ik绑定骨骼名称
    public var target:String = null;//IK约束的目标骨骼名称
    public var bendPositive:Boolean = true;//弯曲方向，默认为true
    public var chain:int=0;//影响的骨骼数量
    public var weight:Number=1;//权重
}

}
