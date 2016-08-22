/**
 * Created by zhouzhanglin on 16/8/19.
 */
package {
import flash.geom.Matrix;
import flash.geom.Point;
import flash.utils.Dictionary;

import utils.MD5;

public class ParseJson {
    public function ParseJson() {
    }

    private var _textureData:String;//spine的材质数据
    private var _spineData:Object;//spine数据对象，最终会将这个对象生成json
    private var _armatureObj:Object;//dragonBone中的一个armature
    private var _defaultSkinsSlotKV:Dictionary = null;//默认skin ,key为slot name,value为dragonBone display数组
    private var _perKeyTime:Number = 0.02;
    private var _textureKV:Dictionary = null;

    private var _bonesKV:Dictionary = null; //key为bone name ,value为dragonBone数据
    private var _slotsKV:Dictionary = null; //key为slot name ,value为dragonBone数据

    public function get spineData():Object{
        return _spineData;
    }
    public function get textureData():String{
        return _textureData;
    }

    /**
     * 解析材质json
     * @param json
     */
    public function parseTextureJosn(json:String):void
    {
        _textureKV = new Dictionary();
        var jsonObject:Object = JSON.parse(json);
        var n:String= "\n";
        var tab:String="  ";
        _textureData = "";
        _textureData = _textureData.concat(jsonObject["imagePath"]+n);
        _textureData = _textureData.concat("size: 0,0"+n);
        _textureData = _textureData.concat("format: RGBA8888"+n);
        _textureData = _textureData.concat("filter: Linear,Linear"+n);
        _textureData = _textureData.concat("repeat: none"+n);
        var subTexture:Array = jsonObject["SubTexture"] as Array;
        var len :uint=subTexture.length;
        for(var i:uint=0;i<len;++i){
            var textureObj:Object = subTexture[i];
            _textureKV[textureObj["name"]] = textureObj;

            _textureData = _textureData.concat(textureObj["name"]+n);
            _textureData = _textureData.concat(tab+"rotate: false"+n);
            _textureData = _textureData.concat(tab+"xy: "+textureObj["x"]+" ,"+textureObj["y"]+n);
            _textureData = _textureData.concat(tab+"size: "+textureObj["width"]+" ,"+textureObj["height"]+n);

            if(textureObj.hasOwnProperty("frameWidth"))
                _textureData = _textureData.concat(tab+"orig: "+textureObj["frameWidth"]+" ,"+textureObj["frameHeight"]+n);
            else
                _textureData = _textureData.concat(tab+"orig: "+textureObj["width"]+" ,"+textureObj["height"]+n);

            if(textureObj.hasOwnProperty("frameX"))
                _textureData = _textureData.concat(tab+"offset: "+textureObj["frameX"]+" ,"+textureObj["frameY"]+n);
            else
                _textureData = _textureData.concat(tab+"offset: 0,0"+n);

            _textureData = _textureData.concat(tab+"index: -1"+n);
        }
    }


    /**
     * 解析动画json
     * @param json
     */
    public function parseAnimJson(json:String):void
    {
        var jsonObject:Object = JSON.parse(json);
        if(jsonObject.hasOwnProperty("frameRate")){
            _perKeyTime = 1/jsonObject["frameRate"];
        }
        _spineData = new Object();
        _spineData["skeleton"] = new Object();
        _spineData["skeleton"].hash = MD5.hash(json);
        _spineData["skeleton"].spine="3.1.0";
        _spineData["skeleton"].images="";

        if(jsonObject.hasOwnProperty("armature")){
            var armatures:Array = jsonObject["armature"] as Array;
            for(var i:int=0;i<armatures.length;++i){
                _armatureObj = armatures[i];
                if(_armatureObj.hasOwnProperty("frameRate")){
                    _perKeyTime = 1/_armatureObj["frameRate"];
                }
                _defaultSkinsSlotKV = new Dictionary();
                _bonesKV = new Dictionary();
                _slotsKV = new Dictionary();
                parseSkins();
                parseBones();
                parseSlots();
                parseAnims();
                break;
            }
        }
    }

    private function parseBones():void{
        if(_armatureObj.hasOwnProperty("bone")) {
            var spine_bones:Array = [];
            _spineData["bones"] = spine_bones;

            var db_bones:Array = _armatureObj["bone"] as Array;
            var db_bones_len:uint = db_bones.length;
            for(var i:int=0;i<db_bones_len;++i){
                var spine_bone:Object = new Object();
                spine_bones.push(spine_bone);

                var db_bone:Object = db_bones[i];
                if(db_bone.hasOwnProperty("name")){ //骨骼名字
                    var boneName:String = db_bone["name"].toString();
                    spine_bone["name"] = boneName;
                    _bonesKV[boneName] = db_bone;
                }
                if(db_bone.hasOwnProperty("parent")){//骨骼的父骨骼
                    var parentBoneName:String = db_bone["parent"].toString();
                    spine_bone["parent"] = parentBoneName;
                }
                if(db_bone.hasOwnProperty("length")){//length
                    var length:Number = Number(db_bone["length"]);
                    if(length>0){
                        spine_bone["length"] = length;
                    }
                }
                if(db_bone.hasOwnProperty("transform")){ //transform
                    var transform:Object = db_bone["transform"];
                    if(transform.hasOwnProperty("x")) spine_bone["x"] = Number(transform["x"]);
                    if(transform.hasOwnProperty("y")) spine_bone["y"] = -Number(transform["y"]);
                    if(transform.hasOwnProperty("skX")) spine_bone["rotation"] = -Number(transform["skX"]);
                    if(transform.hasOwnProperty("scX")) spine_bone["scaleX"] = Number(transform["scX"]);
                    if(transform.hasOwnProperty("scY")) spine_bone["scaleY"] = Number(transform["scY"]);
                }
                if(db_bone.hasOwnProperty("inheritRotation")){
                    if(int(db_bone["inheritRotation"])==0){
                        spine_bone["inheritRotation"] = false;
                    }
                }
                if(db_bone.hasOwnProperty("inheritScale")){
                    if(int(db_bone["inheritScale"])==0){
                        spine_bone["inheritScale"] = false;
                    }
                }
            }
        }

    }

    private function parseSlots():void{
        if(_armatureObj.hasOwnProperty("slot")){
            var spine_slots:Array = [];
            _spineData["slots"] = spine_slots;

            var db_slots:Array = _armatureObj["slot"] as Array;
            var db_slots_len:uint = db_slots.length;
            for(var i:int = 0;i<db_slots_len;++i){
                var spine_slot:Object = new Object();
                spine_slots.push(spine_slot);

                var db_slot:Object = db_slots[i];
                //slot name
                var slotName:String = db_slot["name"].toString();
                spine_slot["name"] = slotName;
                _slotsKV[slotName] = db_slot;

                var displayIndex:int = 0;
                if(db_slot.hasOwnProperty("displayIndex")){
                    displayIndex = int(db_slot["displayIndex"]);
                }
                if(displayIndex>-1){
                    if(_defaultSkinsSlotKV.hasOwnProperty(slotName)){
                        spine_slot["attachment"] = _defaultSkinsSlotKV[slotName][displayIndex].name;
                    }
                }

                if(db_slot.hasOwnProperty("parent")){ //parent bone name
                    spine_slot["bone"] = db_slot["parent"].toString();
                }
                if(db_slot.hasOwnProperty("blendMode")){ //blendMode name
                    spine_slot["blendMode"] = db_slot["blendMode"].toString();
                }
                if(db_slot.hasOwnProperty("color")){ //color
                    var db_color:Object = db_slot["color"];
                    var color:Object = {
                        r:255,g:255,b:255,a:255
                    };
                    if(db_color.hasOwnProperty("aM")) color.a = uint(Number(db_color["aM"])*2.55);
                    if(db_color.hasOwnProperty("rM")) color.r = uint(Number(db_color["rM"])*2.55);
                    if(db_color.hasOwnProperty("gM")) color.g = uint(Number(db_color["gM"])*2.55);
                    if(db_color.hasOwnProperty("bM")) color.b = uint(Number(db_color["bM"])*2.55);
                    spine_slot["color"]=rgbaToHex(color.r,color.g,color.b,color.a);
                }
            }
        }
    }

    private function parseSkins():void{
        if(_armatureObj.hasOwnProperty("skin")){
            var spine_skins:Object=new Object();
            _spineData["skins"] = spine_skins;

            var db_skins:Array = _armatureObj["skin"] as Array;
            var db_skins_len:uint = db_skins.length;
            for(var i:uint = 0;i<db_skins_len ; ++i){
                var db_skin:Object = db_skins[i];

                var spine_skin:Object = new Object();
                if(db_skin["name"].length==0){
                    spine_skins["default"] = spine_skin;
                }else{
                    spine_skins[db_skin["name"]] = spine_skin;
                }

                if(db_skin.hasOwnProperty("slot")){
                    var db_slots:Array = db_skin["slot"] as Array;
                    var db_slots_len = db_slots.length;
                    for(var j:uint =0 ;j<db_slots_len;++j){
                        var db_slot:Object = db_slots[j];

                        var spine_slot:Object = new Object();
                        spine_skin[db_slot["name"]] = spine_slot;

                        if(db_slot.hasOwnProperty("display")){
                            var displays:Array = db_slot["display"] as Array;//此slot中的对象
                            if(i==0){
                                _defaultSkinsSlotKV[db_slot["name"]] = displays;
                            }
                            var displays_len:uint = displays.length;
                            for(var z:uint=0;z<displays_len;++z){
                                var display:Object = displays[z];

                                var spine_display:Object = new Object();
                                spine_slot[display["name"]] = spine_display;

                                //width,height
                                spine_display["width"] = _textureKV[display["name"]].width;
                                spine_display["height"] = _textureKV[display["name"]].height;

                                if(display.hasOwnProperty("type") && display["type"]!="image"){ //类型
                                    var type:String = "mesh";
                                    if(display["type"]=="mesh" && display.hasOwnProperty("weights")){
                                        type="weightedmesh";
                                    }
                                    spine_display["type"]=type;
                                }
                                if(display.hasOwnProperty("transform")){ //transform
                                    var transform:Object = display["transform"];
                                    if(transform.hasOwnProperty("x")) spine_display["x"] = Number(transform["x"]);
                                    if(transform.hasOwnProperty("y")) spine_display["y"] = -Number(transform["y"]);
                                    if(transform.hasOwnProperty("skX")) spine_display["rotation"] = -Number(transform["skX"]);
                                    if(transform.hasOwnProperty("scX")) spine_display["scaleX"] = Number(transform["scX"]);
                                    if(transform.hasOwnProperty("scY")) spine_display["scaleY"] = Number(transform["scY"]);
                                }
                                if(display.hasOwnProperty("edges")) spine_display["edges"] = display["edges"];
                                if(display.hasOwnProperty("uvs")) spine_display["uvs"] = display["uvs"];
                                if(display.hasOwnProperty("triangles")) {
                                    var triangles:Array = display["triangles"] as Array;
                                    spine_display["triangles"] = triangles;
                                    spine_display["hull"] = triangles.length/3;
                                }
                                if(display.hasOwnProperty("vertices"))
                                {
                                    var vertices:Array = display["vertices"] as Array;
                                    if(display.hasOwnProperty("weights")){
                                        var slotPoseArr :Array = display["slotPose"] as Array;
                                        var slotPose:Matrix = new Matrix(slotPoseArr[0],slotPoseArr[1],slotPoseArr[2],
                                                slotPoseArr[3],slotPoseArr[4],slotPoseArr[5]);

                                        var bonePoseArr:Array = display["bonePose"] as Array;
                                        var bonePoseKV:Dictionary = new Dictionary();
                                        for(var m:uint = 0;m<bonePoseArr.length;m+=7){
                                            var matrix:Matrix=new Matrix(bonePoseArr[m+1],bonePoseArr[m+2],bonePoseArr[m+3],
                                            bonePoseArr[m+4],bonePoseArr[m+5],bonePoseArr[m+6]);
                                            matrix.invert();
                                            bonePoseKV["BoneIndex"+bonePoseArr[m]] = matrix;
                                        }

                                        var vertices_len:uint = vertices.length;
                                        var db_weights:Array=display["weights"] as Array;
                                        var spine_vertices:Array = [];
                                        for(var k:uint = 0;k<vertices_len;k+=2){
                                            var p:Point = slotPose.transformPoint(new Point(vertices[k],vertices[k+1]));
                                            spine_vertices.push(p.x);//vertexX
                                            spine_vertices.push(-p.y);//vertexY

                                            var wIndex :uint = k/2*3;
                                            var bIndex:uint = uint(db_weights[wIndex+1]);
                                            spine_vertices.push(bIndex);//骨骼索引
                                            var spine_bone:Object = _spineData["bones"][bIndex];
                                            p = (bonePoseKV["BoneIndex"+bIndex] as Matrix).transformPoint(new Point(spine_bone.x,spine_bone.y));
                                            spine_vertices.push(p.x);//绑定的x
                                            spine_vertices.push(-p.y);//绑定的y
                                            spine_vertices.push(db_weights[wIndex+2]);//权重
                                        }
                                        spine_display["vertices"] = spine_vertices;
                                    }else{
                                        spine_display["vertices"] = vertices;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private function parseAnims():void{
        if(_armatureObj.hasOwnProperty("animation")){
            var spine_Anims:Object=new Object();
            _spineData["animations"] = spine_Anims;

            var db_animsArr:Array = _armatureObj["animation"] as Array;
            var db_anims_len:uint =  db_animsArr.length;
            for(var i:uint = 0 ;i<db_anims_len;++i){
                var db_animObj:Object = db_animsArr[i];

                var spine_animObj:Object = new Object();
                spine_Anims[db_animObj["name"]] = spine_animObj;

                if(db_animObj.hasOwnProperty("bone")){
                    var spine_bonesArr:Object = new Object();
                    spine_animObj["bones"] = spine_bonesArr;

                    parseBoneAnims(db_animObj,spine_bonesArr);
                }
                if(db_animObj.hasOwnProperty("slot")){
                    var spine_slotArr:Object = new Object();
                    spine_animObj["slots"] = spine_slotArr;

                    parseSlotAnims(db_animObj,spine_slotArr);
                }
            }
        }
    }

    private function parseSlotAnims(db_animObj:Object,spine_bonesArr:Object):void{
        var db_animSlotArr:Array = db_animObj["slot"] as Array;
        var db_animSlotArr_len:uint = db_animSlotArr.length;
        for(var i:uint = 0;i<db_animSlotArr_len;++i){
            var db_animSlotObj:Object = db_animSlotArr[i];

            //spine attachment, color
            var spine_attachment:Array = [];
            var spine_color:Array = [];

            //db frame
            var frames:Array = db_animSlotObj["frame"] as Array;
            var frames_len:uint = frames.length;
            //time
            var during:Number = 0;
            for(var j:uint = 0 ;j<frames_len;++j){
                var frame:Object = frames[j];
                if(j<frames_len-1){
                    if(frame.hasOwnProperty("curve")){
                        var curve:Object=frame["curve"];
                    }else if(frame.hasOwnProperty("tweenEasing")){
                        if(frame["tweenEasing"]==null){
                            curve = "stepped";
                        }
                    }
                }
                var slotName:String = db_animSlotObj["name"];

                var displayIndex:int = 0;
                if(frame.hasOwnProperty("displayIndex")){
                    displayIndex = int(frame["displayIndex"]);
                }
                if(displayIndex==-1){
                    if(spine_attachment.length==0 || spine_attachment[spine_attachment.length-1].name!=null){
                        spine_attachment.push({
                            "time":during,
                            "name":null
                        });
                    }
                }else{
                    var attachment:String = _defaultSkinsSlotKV[slotName][displayIndex].name;
                    if(spine_attachment.length==0 || spine_attachment[spine_attachment.length-1].name!=attachment){
                        spine_attachment.push({
                            "time":during,
                            "name":attachment
                        });
                    }
                }

                if(frame.hasOwnProperty("color")){
                    var db_color:Object = frame["color"];
                    var color:Object = {
                        r:255,g:255,b:255,a:255
                    };
                    if(db_color.hasOwnProperty("aM")) color.a = uint(Number(db_color["aM"])*2.55);
                    if(db_color.hasOwnProperty("rM")) color.r = uint(Number(db_color["rM"])*2.55);
                    if(db_color.hasOwnProperty("gM")) color.g = uint(Number(db_color["gM"])*2.55);
                    if(db_color.hasOwnProperty("bM")) color.b = uint(Number(db_color["bM"])*2.55);
                    var colorDec:String = rgbaToHex(color.r,color.g,color.b,color.a);
                    if(curve){
                        spine_color.push({
                            "time":during,
                            "color":colorDec,
                            "curve":curve
                        });
                    }else {
                        spine_color.push({
                            "time": during,
                            "color": colorDec
                        });
                    }
                }

                during += _perKeyTime*frame["duration"];
                curve = null;
            }
            if(spine_attachment.length>0||spine_color.length>0){
                var spine_slot:Object = new Object();
                spine_bonesArr[db_animSlotObj["name"]] = spine_slot;

                if(spine_attachment.length>0){
                    spine_slot["attachment"]=spine_attachment;
                }
                if(spine_color.length>0){
                    spine_slot["color"]=spine_color;
                }
            }
        }
    }

    private function parseBoneAnims(db_animObj:Object,spine_bonesArr:Object):void{
        var db_animBoneArr:Array = db_animObj["bone"] as Array;
        var db_animBoneArr_len:uint = db_animBoneArr.length;
        for(var i:uint = 0;i<db_animBoneArr_len;++i){
            var db_animBoneObj:Object = db_animBoneArr[i];
            var boneName:String = db_animBoneObj["name"];
            //spine translate , scale , rotate
            var spine_translate:Array=[];
            var spine_scale:Array=[];
            var spine_rotate:Array=[];
            //db frame
            var frames:Array = db_animBoneObj["frame"] as Array;
            var frames_len:uint = frames.length;
            //time
            var during:Number = 0;
            for(var j:uint = 0 ;j<frames_len;++j){
                var frame:Object = frames[j];
                if(j<frames_len-1){
                    if(frame.hasOwnProperty("curve")){
                        var curve:Object=frame["curve"];
                    }else if(frame.hasOwnProperty("tweenEasing")){
                        if(frame["tweenEasing"]==null){
                            curve = "stepped";
                        }
                    }
                }
                if(frame.hasOwnProperty("transform")){
                    var transform:Object = frame["transform"];
                    if(transform.hasOwnProperty("x")||transform.hasOwnProperty("y")){
                        var px:Number = Number(transform["x"]);
                        var py:Number = -Number(transform["y"]);
                        if(!px) px=0;
                        if(!py) py=0;
                        if(curve){
                            spine_translate.push({
                                "x":px,
                                "y":py,
                                "time":during,
                                "curve":curve
                            });
                        }else{
                            spine_translate.push({
                                "x":px,
                                "y":py,
                                "time":during
                            });
                        }
                    }
                    if(transform.hasOwnProperty("skX")){
                        var angle:Number = -Number(transform["skX"]);
                        if(!angle) angle=0;
                        if(curve){
                            spine_rotate.push({
                                "angle":angle ,
                                "time":during,
                                "curve":curve
                            });
                        }else{
                            spine_rotate.push({
                                "angle":angle ,
                                "time":during
                            });
                        }

                    }
                    if(transform.hasOwnProperty("scX")||transform.hasOwnProperty("scY")){
                        var scx:Number = Number(transform["scX"]);
                        var scy:Number = Number(transform["scY"]);
                        if(!scx) scx=0;
                        if(!scy) scy=0;
                        if(curve){
                            spine_scale.push({
                                "x":scx,
                                "y":scy,
                                "time":during,
                                "curve":curve
                            });
                        }else{
                            spine_scale.push({
                                "x":scx,
                                "y":scy,
                                "time":during
                            });
                        }
                    }
                }
                during += _perKeyTime*frame["duration"];
                curve = null;
            }

            if(spine_translate.length>0 || spine_scale.length>0 || spine_rotate.length>0){
                var spine_bone:Object = new Object();
                spine_bonesArr[boneName] = spine_bone;

                if(spine_translate.length>0){
                    spine_bone["translate"] = spine_translate;
                }
                if(spine_scale.length>0){
                    spine_bone["scale"] = spine_scale;
                }
                if(spine_rotate.length>0){
                    spine_bone["rotate"] = spine_rotate;
                }
            }
        }
    }


    public static function rgbaToHex(r:uint, g:uint, b:uint, a:uint):String
    {
        var s = (r << 16 | g << 8 | b).toString(16);
        while(s.length < 6) s="0"+s;
        var sa = a.toString(16);
        while(sa.length < 2) sa="0"+sa;
        return s+sa;
    }



    public static function getNumber(dic:Object,key:String,defaultValue:Number):Number{
        if(dic.hasOwnProperty(key)){
            return Number(dic[key]);
        }
        return defaultValue;
    }
}
}
