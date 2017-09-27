/**
 * Created by zhouzhanglin on 16/8/19.
 * 下面代码中db缩写表示dragonBone
 */
package {
import flash.display.DisplayObjectContainer;
import flash.display.Sprite;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.utils.Dictionary;

import utils.MD5;

public class ParseJson {
    public function ParseJson() {

    }

    static const Frame_Type_Frame:uint = 0;
    static const Frame_Type_DisplayFrame:uint = 1;
    static const Frame_Type_ColorFrame:uint = 2;
    static const Frame_Type_TranslateFrame:uint = 3;
    static const Frame_Type_ScaleFrame:uint = 4;
    static const Frame_Type_RotateFrame:uint = 5;

    private var _armatureName:String;//骨架名称
    private var _textureData:String;//spine的材质数据
    private var _spineData:Object;//spine数据对象，最终会将这个对象生成json
    private var _armatureObj:Object;//dragonBone中的一个armature
    private var _defaultSkinsSlotKV:Dictionary = null;//默认skin ,key为slot name,value为dragonBone display数组
    private var _perKeyTime:Number = 0.02;
    private var _textureKV:Dictionary = null;
    private var _spine_eventsList:Object = null;

    private var _bonesKV:Dictionary = null; //key为bone name ,value为dragonBone数据
    private var _slotsKV:Dictionary = null; //key为slot name ,value为dragonBone数据
    private var _displayModel:Sprite = null ;//用于模拟树状
    private var _boneDisplays:Array = null;
    private var _slotsNames:Array= null;
    private var _jsonObject:Object = null;

    public function get spineData():Object{
        return _spineData;
    }
    public function get textureData():String{
        return _textureData;
    }
    public function get armatureName():String{
        return _armatureName;
    }

    private var _armatureIndex:int = 0;
    private var _md5:String;

    /**
     * 解析材质json
     * @param json
     */
    public function parseTextureJsons(jsons:Array):void
    {
        _textureKV = new Dictionary();
        var n:String= "\n";
        var tab:String="  ";
        _textureData = "";

        for(var i:uint = 0;i<jsons.length;++i){
            var json:String = jsons[i];
            var jsonObject:Object = JSON.parse(json);
            _textureData = _textureData.concat(n);
            _textureData = _textureData.concat(jsonObject["imagePath"]+n);
            _textureData = _textureData.concat("size: 0,0"+n);
            _textureData = _textureData.concat("format: RGBA8888"+n);
            _textureData = _textureData.concat("filter: Linear,Linear"+n);
            _textureData = _textureData.concat("repeat: none"+n);
            var subTexture:Array = jsonObject["SubTexture"] as Array;
            var len :uint=subTexture.length;
            for(var j:uint=0;j<len;++j){
                var textureObj:Object = subTexture[j];
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
    }


    /**
     * 解析动画json
     * @param json
     */
    public function parseAnimJson(json:String):void
    {
        _armatureIndex = 0;
        _jsonObject = JSON.parse(json);
        if(_jsonObject.hasOwnProperty("frameRate") && int(_jsonObject["frameRate"]>0)){
            _perKeyTime = 1/_jsonObject["frameRate"];
        }else{
            _perKeyTime = 1/24;
        }
        _md5 = MD5.hash(json);
        nextArmature();
    }

    /**
     * 是否还有下一个骨架数据
     * @return
     */
    public function hasNextArmature():Boolean{
        if(_jsonObject.hasOwnProperty("armature")){
            var armatures:Array = _jsonObject["armature"] as Array;
            if(_armatureIndex<armatures.length){
                return true;
            }
        }
        return false;
    }

    public function nextArmature(){
        if(_jsonObject.hasOwnProperty("armature")){
            var armatures:Array = _jsonObject["armature"] as Array;
            for(var i:int=_armatureIndex;i<armatures.length;++i){
                _spineData = new Object();
                _spineData["skeleton"] = new Object();
                _spineData["skeleton"].hash = _md5;
                _spineData["skeleton"].spine="3.5.0";
                _spineData["skeleton"].images="";

                _spine_eventsList = null;

                _armatureObj = armatures[i];
                if(_armatureObj.hasOwnProperty("frameRate") && int(_armatureObj["frameRate"]>0)){
                    _perKeyTime = 1/_armatureObj["frameRate"];
                }
                _armatureName = _armatureObj["name"];
                _defaultSkinsSlotKV = new Dictionary();
                _bonesKV = new Dictionary();
                _slotsKV = new Dictionary();
                _displayModel = new Sprite();
                _boneDisplays= [];
                parseSlotAndBone();
                convertBones();
                convertSkinsData();
                convertSlots();
                convertIKs();
                convertAnims();
                if(_spine_eventsList!=null){
                    _spineData["events"] = _spine_eventsList;
                }
                break;
            }
        }
        ++_armatureIndex;
    }

    private function parseSlotAndBone():void{
        if(_armatureObj.hasOwnProperty("bone")) {
            var db_bones:Array = _armatureObj["bone"] as Array;
            var db_bones_len:uint = db_bones.length;
            for(var i:int=0;i<db_bones_len;++i){
                var db_bone:Object = db_bones[i];

                db_bone["tx"]=  db_bone["ty"] =  db_bone["angle"] = 0;
                db_bone["sx"]=  db_bone["sy"] =  1;

                if(db_bone.hasOwnProperty("transform")){ //transform
                    var transform:Object = db_bone["transform"];
                    if(transform.hasOwnProperty("x")) db_bone["tx"] = Number(transform["x"]);
                    if(transform.hasOwnProperty("y")) db_bone["ty"] = Number(transform["y"]);
                    if(transform.hasOwnProperty("skX")) db_bone["angle"] = Number(transform["skX"]);
                    if(transform.hasOwnProperty("scX")) db_bone["sx"] = Number(transform["scX"]);
                    if(transform.hasOwnProperty("scY")) db_bone["sy"] = Number(transform["scY"]);
                }

                var displayBone:Sprite = new Sprite();
                displayBone.rotation = db_bone["angle"];
                displayBone.scaleX = db_bone["sx"];
                displayBone.scaleY = db_bone["sy"];
                displayBone.x = db_bone["tx"];
                displayBone.y = db_bone["ty"];
                db_bone["displayBone"] = displayBone;

                _boneDisplays.push(displayBone);

                var boneName:String = db_bone["name"].toString();
                _bonesKV[boneName] = db_bone;
            }
        }

        if(_armatureObj.hasOwnProperty("slot")){
            var db_slots:Array = _armatureObj["slot"] as Array;
            var db_slots_len:uint = db_slots.length;

            _slotsNames = [];
            for(var i:int = 0;i<db_slots_len;++i){

                var db_slot:Object = db_slots[i];

                //slot name
                var slotName:String = db_slot["name"].toString();
                _slotsKV[slotName] = db_slot;
                _slotsNames.push(slotName);

                if(db_slot.hasOwnProperty("parent")){ //parent bone name
                     var displaySlot:Sprite = new Sprite();
                    (_bonesKV[db_slot["parent"]]["displayBone"] as Sprite).addChild(displaySlot);

                    db_slot["displaySlot"] = displaySlot;
                }
            }
        }

        //设置bone的层级
        if(_armatureObj.hasOwnProperty("bone")) {
            var db_bones:Array = _armatureObj["bone"] as Array;
            var db_bones_len:uint = db_bones.length;
            for (var i:int = 0; i < db_bones_len; ++i) {
                var db_bone:Object = db_bones[i];

                if(db_bone.hasOwnProperty("parent")) { //parent bone name
                    (_bonesKV[db_bone["parent"]]["displayBone"] as Sprite).addChild(db_bone["displayBone"] as Sprite);
                }else{
                    _displayModel = db_bone["displayBone"] as Sprite;
                }
            }
        }
    }

    private function convertBones():void{
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

    private function convertIKs():void{
        if(_armatureObj.hasOwnProperty("ik")){
            var db_iks:Array = _armatureObj["ik"];
            var db_iks_len:uint = db_iks.length;
            if(db_iks_len==0) return;

            var spine_iks:Array = [];
            for(var i:uint = 0;i<db_iks_len;++i){
                var db_ik_Obj :Object = db_iks[i];
                var spine_ik_obj:Object=  new Object();
                spine_iks.push(spine_ik_obj);

                spine_ik_obj["name"] = db_ik_Obj["name"];//ik约束名称
                spine_ik_obj["target"] = db_ik_Obj["target"];//ik约束的目标点

                if(db_ik_Obj.hasOwnProperty("bendPositive")) spine_ik_obj["bendPositive"] = db_ik_Obj["bendPositive"];
                else spine_ik_obj["bendPositive"] = true; //db中默认为true

                if(db_ik_Obj.hasOwnProperty("weight")) spine_ik_obj["mix"] = db_ik_Obj["weight"];

                if(db_ik_Obj.hasOwnProperty("bone")){
                    var db_bone:String = db_ik_Obj["bone"];
                    if(db_ik_Obj.hasOwnProperty("chain")){
                        var spine_bones:Array = [db_bone];
                        var boneSprite:DisplayObjectContainer = _bonesKV[db_bone]["displayBone"] as DisplayObjectContainer;
                        var chain:int = int(db_ik_Obj["chain"]);
                        boneSprite = boneSprite.parent;
                        while(chain>0){
                            spine_bones.push(boneSprite.name);
                            boneSprite = boneSprite.parent;
                            chain--;
                        }
                    }
                }
            }
        }
    }

    private function convertSlots():void{
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

    private function convertSkinsData():void{
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
                        var slotName:String = db_slot["name"].toString();
                        spine_skin[slotName] = spine_slot;
                        var slotDisplay:Sprite = _slotsKV[slotName]["displaySlot"] as Sprite;

                        if(db_slot.hasOwnProperty("display")){
                            var displays:Array = db_slot["display"] as Array;//此slot中的对象
                            if(i==0){
                                _defaultSkinsSlotKV[slotName] = displays;
                            }
                            var displays_len:uint = displays.length;
                            for(var z:uint=0;z<displays_len;++z){
                                var display:Object = displays[z];

                                var spine_attachment:Object = new Object();
                                var attachment:String = display["name"].toString();
                                spine_slot[attachment] = spine_attachment;

                                _slotsKV[slotName][attachment] = display;

                                //width,height
                                if(display.hasOwnProperty("width")){
                                    spine_attachment["width"] = display["width"];
                                }else{
                                    spine_attachment["width"] = _textureKV[display["name"]].width;
                                }
                                if(display.hasOwnProperty("height")){
                                    spine_attachment["height"] = display["height"];
                                }else{
                                    spine_attachment["height"] = _textureKV[display["name"]].height;
                                }

                                var isImage:Boolean = true;

                                if(display.hasOwnProperty("type") && display["type"]!="image"){ //类型
                                    var type:String = "mesh";
                                    spine_attachment["type"]=type;
                                    isImage = false;
                                }

                                var tx:Number,ty:Number,sx:Number,sy:Number,angle:Number;
                                tx=ty=angle=0;
                                sx=sy = 1;
                                if(display.hasOwnProperty("transform")){ //transform
                                    var transform:Object = display["transform"];
                                    if(transform.hasOwnProperty("x")) {
                                        tx = Number(transform["x"]);
                                        if(isImage) spine_attachment["x"] = tx;
                                    }
                                    if(transform.hasOwnProperty("y")) {
                                        ty = Number(transform["y"]);
                                        if(isImage) spine_attachment["y"] = -ty;
                                    }
                                    if(transform.hasOwnProperty("skX")) {
                                        angle = Number(transform["skX"]);
                                        if(isImage) spine_attachment["rotation"] = -angle;
                                    }
                                    if(transform.hasOwnProperty("scX")) {
                                        sx = Number(transform["scX"]);
                                        if(isImage) spine_attachment["scaleX"] = sx;
                                    }
                                    if(transform.hasOwnProperty("scY")) {
                                        sy = Number(transform["scY"]);
                                        if(isImage) spine_attachment["scaleY"] = sy;
                                    }
                                }
                                var displayAttach:Sprite = new Sprite();
                                displayAttach.rotation = angle;
                                displayAttach.x = tx;
                                displayAttach.y = ty;
                                displayAttach.scaleX = sx;
                                displayAttach.scaleY = sy;
                                displayAttach.name = attachment;
                                slotDisplay.addChild(displayAttach);

                                if(display.hasOwnProperty("edges")) {
                                    spine_attachment["edges"] = display["edges"];
                                    var edges_len:uint = spine_attachment["edges"].length;
                                    for(var t:uint=0; t< edges_len;++t){
                                        spine_attachment["edges"][t]*=2;
                                    }
                                }
                                if(display.hasOwnProperty("uvs")) spine_attachment["uvs"] = display["uvs"];
                                if(display.hasOwnProperty("triangles")) {
                                    var triangles:Array = display["triangles"] as Array;
                                    //三角形顺序相反
                                    for(var t:uint =0;t<triangles.Length;t+=3){
                                        var f1 = triangles[t];
                                        var f3 = triangles[t+2];
                                        triangles[t] = f3;
                                        triangles[t+2] = f1;
                                    }
                                    spine_attachment["triangles"] = triangles;
                                    spine_attachment["hull"] = triangles.length/3;
                                }


                                if(display.hasOwnProperty("vertices"))
                                {
                                    var vertices:Array = display["vertices"] as Array;
                                    if(display.hasOwnProperty("weights")){
                                        //spine weight vertices格式:bonecount,boneindex,vx,vy,weight
                                        var slotPoseArr :Array = display["slotPose"] as Array;
                                        var slotPose:Matrix = new Matrix(slotPoseArr[0],slotPoseArr[1],slotPoseArr[2],
                                                slotPoseArr[3],slotPoseArr[4],slotPoseArr[5]);

                                        var bonePoseArr:Array = display["bonePose"] as Array;
                                        var bonePoseKV:Dictionary = new Dictionary();
                                        for(var m:uint = 0;m<bonePoseArr.length;m+=7){
                                            var matrix:Matrix=new Matrix(bonePoseArr[m+1],bonePoseArr[m+2],bonePoseArr[m+3],
                                            bonePoseArr[m+4],bonePoseArr[m+5],bonePoseArr[m+6]);
                                            matrix.invert();//bonePose的全局Matrix，所以这儿需要转成本地Matrix
                                            bonePoseKV["BoneIndex"+bonePoseArr[m]] = matrix;
                                        }

                                        var vertices_len:uint = vertices.length;
                                        var db_vertices:Vector.<Point> = new Vector.<Point>(vertices_len/2);//db的顶点
                                        db_vertices.fixed = true;
                                        for(var k:uint = 0;k<vertices_len;k+=2) {
                                            db_vertices[k/2] = slotPose.transformPoint(new Point(vertices[k], vertices[k + 1]));
                                        }

                                        var spine_weight_vertices:Array = [];//spine 的weight数据
                                        spine_attachment["vertices"] = spine_weight_vertices;

                                        var db_weights:Array=display["weights"] as Array;//db权重
                                        var db_weights_len:uint=db_weights.length;
                                        var vertexIndex:uint = 0;
                                        for(var k:uint = 0 ;k<db_weights_len;++k){
                                            var boneCount:uint = uint(db_weights[k]);//骨骼数量
                                            spine_weight_vertices.push(boneCount);

                                            var vertex:Point =db_vertices[vertexIndex];

                                            for(var t:uint=0;t<boneCount*2;t+=2){
                                                var boneIdx:uint = uint(db_weights[k+t+1]);//骨骼索引
                                                var weight:Number =db_weights[k+t+2]; //权重

                                                var boneMatrix:Matrix = bonePoseKV["BoneIndex"+boneIdx] as Matrix;
                                                var temp:Point = boneMatrix.transformPoint(vertex);

                                                spine_weight_vertices.push(boneIdx);
                                                spine_weight_vertices.push(temp.x);
                                                spine_weight_vertices.push(-temp.y);
                                                spine_weight_vertices.push(weight);
                                            }
                                            k+=boneCount*2;
                                            ++vertexIndex;
                                        }
                                    }else{
                                        var mat:Matrix = new Matrix();
                                        mat.concat(displayAttach.transform.matrix);
                                        mat.concat(displayAttach.parent.transform.matrix);

                                        var vertices_len:uint = vertices.length;
                                        var spine_vertices:Array = [];

                                        for(var k:uint = 0;k<vertices_len;k+=2){
                                            var p:Point = mat.transformPoint(new Point(vertices[k],vertices[k+1]));
                                            spine_vertices.push(p.x);//vertexX
                                            spine_vertices.push(-p.y);//vertexY
                                        }
                                        spine_attachment["vertices"] = spine_vertices;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private function convertAnims():void{
        if(_armatureObj.hasOwnProperty("animation")){
            var spine_Anims:Object=new Object();
            _spineData["animations"] = spine_Anims;

            var db_animsArr:Array = _armatureObj["animation"] as Array;
            var db_anims_len:uint =  db_animsArr.length;
            for(var i:uint = 0 ;i<db_anims_len;++i){
                var db_animObj:Object = db_animsArr[i];

                var totalFrame:int = db_animObj["duration"] as int;

                var spine_animObj:Object = new Object();
                spine_Anims[db_animObj["name"]] = spine_animObj;

                if(db_animObj.hasOwnProperty("bone")){
                    var spine_bonesArr:Object = new Object();
                    spine_animObj["bones"] = spine_bonesArr;

                    parseBoneAnims(db_animObj,spine_bonesArr,totalFrame);
                }
                if(db_animObj.hasOwnProperty("slot")){
                    var spine_slotArr:Object = new Object();
                    spine_animObj["slots"] = spine_slotArr;

                    parseSlotAnims(db_animObj,spine_slotArr,totalFrame);
                }
                if(db_animObj.hasOwnProperty("ffd")){
                    var spine_ffdArr:Object = new Object();
                    spine_animObj["deform"] = spine_ffdArr;

                    parseFFDAnims(db_animObj,spine_ffdArr,totalFrame);
                }
                if(db_animObj.hasOwnProperty("frame")){ //帧事件
                    var spine_frame_events:Array = [];
                    parseFrameEvents(db_animObj,spine_frame_events,totalFrame);
                    if(spine_frame_events.length>0){
                        spine_animObj["events"] = spine_frame_events;
                    }
                }
                if(db_animObj.hasOwnProperty("zOrder")){
                    var spine_zorders:Array = [];
                    spine_animObj["draworder"] = spine_zorders;
                    parseZOrderAnims(db_animObj["zOrder"],spine_zorders,totalFrame);
                }
            }
        }
    }

    private function parseZOrderAnims(db_animObj:Object,spine_zorders:Array, totalFrame:int) {
        if (db_animObj.hasOwnProperty("frame")) {
            var db_frames:Array = db_animObj["frame"] as Array;
            var db_frames_len:uint = db_frames.length;
            var during:Number = 0;
            for (var i:uint = 0; i < db_frames_len; ++i) {
                var db_orderObj:Object = db_frames[i];
                if (db_orderObj.hasOwnProperty("zOrder")) {
                    var spine_zOrderObj:Object = new Object();
                    var zorders:Array = db_orderObj["zOrder"] as Array;
                    var db_zorders_len:uint = zorders.length;
                    spine_zOrderObj["time"] = during;
                    spine_zOrderObj["offsets"] = [];
                    for (var j:uint = 0; j < db_zorders_len; j += 2) {
                        var slotIdx:int = int(zorders[j]);
                        var offset:int = int(zorders[j + 1]);
                        var offsetObj:Object = new Object();
                        offsetObj["slot"] = _slotsNames[slotIdx];
                        offsetObj["offset"] = offset;
                        spine_zOrderObj["offsets"].push(offsetObj);
                    }
                    spine_zorders.push(spine_zOrderObj);
                }
                var frame_dur:int = db_orderObj.hasOwnProperty("duration") ? int(db_orderObj["duration"]) : 1;
                if(frame_dur==0){
                    during = _perKeyTime*totalFrame;  //最后一帧
                }else{
                    during += _perKeyTime * frame_dur;
                }
            }
        }
    }

    private function parseFrameEvents(db_animObj:Object,spine_frame_events:Array,totalFrame:int):void{
        var db_events:Array = db_animObj["frame"] as Array;
        var db_events_len :int = db_events.length;

        var during:Number = 0;
        for(var i:uint = 0 ;i<db_events_len ;++i) {
            var db_eventObj:Object = db_events[i];
            if(db_eventObj.hasOwnProperty("event")){
                var eventName = db_eventObj["event"];
                if(_spine_eventsList==null) _spine_eventsList = new Object();
                _spine_eventsList[eventName] = {};//总的events列表

                //当前帧的event
                var spine_evt:Object = new Object();
                spine_evt["time"] = during;
                spine_evt["name"] = eventName;
                if(db_eventObj.hasOwnProperty("action")){
                    spine_evt["string"] = db_eventObj["action"];
                }
                spine_frame_events.push(spine_evt);
            }
            var frame_dur:int = db_eventObj.hasOwnProperty("duration") ? int(db_eventObj["duration"]) : 1;
            if(frame_dur==0){
                during = _perKeyTime*totalFrame;  //最后一帧
            }else{
                during += _perKeyTime * frame_dur;
            }
        }
    }

    private function parseFFDAnims(db_animObj:Object,spine_ffdArr:Object,totalFrame:int):void{
        var db_animFFDArr:Array = db_animObj["ffd"] as Array;
        var db_animFFDArr_len:uint = db_animFFDArr.length;
        for(var i:uint = 0 ;i<db_animFFDArr_len ;++i){
            var db_animFFDObj:Object = db_animFFDArr[i];
            if(db_animFFDObj.hasOwnProperty("frame")){
                var frames:Array = db_animFFDObj["frame"] as Array;
                if(frames.length>0)
                {
                    //skin
                    var db_skin:String = db_animFFDObj["skin"];
                    if(!db_skin) db_skin="default";

                    var spine_skinObj:Object = null;
                    if(spine_ffdArr.hasOwnProperty(db_skin)){
                        spine_skinObj = spine_ffdArr[db_skin];
                    }else{
                        spine_skinObj = new Object();
                        spine_ffdArr[db_skin] = spine_skinObj;
                    }

                    //slot
                    var db_slot_name:String = db_animFFDObj["slot"];
                    var spine_slotObj:Object=null;
                    if(spine_skinObj.hasOwnProperty(db_slot_name)){
                        spine_slotObj=spine_skinObj[db_slot_name];
                    }else{
                        spine_slotObj=  new Object();
                        spine_skinObj[db_slot_name] = spine_slotObj;
                    }

                    //mesh
                    var db_display_name:String = db_animFFDObj["name"];
                    if(!db_display_name) db_display_name = db_slot_name;

                    var spine_meshArr:Array =null;
                    if(spine_slotObj.hasOwnProperty(db_display_name)){
                        spine_meshArr = spine_slotObj[db_display_name];
                    }else{
                        spine_meshArr = [];
                        spine_slotObj[db_display_name] = spine_meshArr;
                    }

                    var displayAttach:Sprite=(_slotsKV[db_slot_name]["displaySlot"] as Sprite).getChildByName(db_display_name) as Sprite;
                    var mat:Matrix = new Matrix();
                    mat.concat(displayAttach.transform.matrix);
                    mat.concat(displayAttach.parent.transform.matrix);
                    var db_display_data:Object = _slotsKV[db_slot_name][db_display_name];//原始skin数据
                    var poseVertices:Array = db_display_data["vertices"] as Array;//原始顶点

                    var haveWeight:Boolean = false;//是否有权重数据
                    if(db_display_data.hasOwnProperty("weights")
                            && db_display_data["weights"]!=null
                            && db_display_data["weights"].length>0){
                        haveWeight = true;
                    }

                    var frames_len:uint = frames.length;
                    var during:Number = 0;
                    for(var j:uint = 0 ;j<frames_len ; ++j){
                        var frame:Object = frames[j];
                        if(frame.hasOwnProperty("vertices")){

                            var spine_frame:Object = new Object();
                            spine_meshArr.push(spine_frame);

                            spine_frame["time"] = during;

                            if(j<frames_len-1){
                                if(frame.hasOwnProperty("curve")){
                                    spine_frame["curve"]=frame["curve"];
                                }else if(frame.hasOwnProperty("tweenEasing")){
                                    if(frame["tweenEasing"]==null){
                                        spine_frame["curve"] = "stepped";
                                    }
                                }
                            }
                            var vertices:Array = frame["vertices"] as Array;
                            var vertices_len:uint = vertices.length;
                            if(vertices_len>0){
                                var offset:int = 0;
                                if(frame.hasOwnProperty("offset")){
                                    offset = spine_frame["offset"] = int(frame["offset"]);
                                }
                                if(offset%2!=0){//奇数offset
                                    offset--;
                                    spine_frame["offset"] = offset;
                                    vertices.unshift(0);
                                    ++vertices_len;
                                }
                                if(vertices_len%2!=0){
                                    ++vertices_len;
                                    vertices.push(0);
                                }

                                //重新计算offset
                                if(offset>0 && db_display_data.hasOwnProperty("weights")){
                                    var db_weights:Array=db_display_data["weights"] as Array;//db权重
                                    var db_weights_len:uint=db_weights.length;
                                    var totalVertex:int = 0;
                                    for(var k:uint = 0 ;k<db_weights_len;++k){
                                        var boneCount:uint = uint(db_weights[k]);//骨骼数量
                                        k+=boneCount*2;
                                        totalVertex += boneCount*2;
                                    }
                                    spine_frame["offset"] = totalVertex-(db_display_data["uvs"].length-offset);
                                }

                                var spine_vertices:Array = [];
                                for(var k:uint = 0;k<vertices_len;k+=2){
                                    //pose中的顶点位置
                                    var originPoint:Point = new Point(poseVertices[offset+k],poseVertices[offset+k+1]);
                                    //现在的位置
                                    var currentPoint:Point = new Point(originPoint.x+vertices[k],originPoint.y+vertices[k+1]);
                                    //转换
                                    if(haveWeight){
                                        originPoint = displayAttach.localToGlobal(originPoint);
                                        currentPoint = displayAttach.localToGlobal(currentPoint);
                                    }else{
                                        originPoint = mat.transformPoint(originPoint);
                                        currentPoint = mat.transformPoint(currentPoint);
                                    }
                                    //重新设置位移
                                    spine_vertices.push(currentPoint.x-originPoint.x);
                                    spine_vertices.push(originPoint.y-currentPoint.y);
                                }
                                if(haveWeight){
                                    calculateDeformAnimWeight(db_display_data,spine_vertices,offset);
                                }
                                spine_frame["vertices"]=spine_vertices;
                            }
                        }
                        var frame_dur:int = frame.hasOwnProperty("duration") ? int(frame["duration"]) : 1;
                        if(frame_dur==0){
                            during = _perKeyTime*totalFrame;  //最后一帧
                        }else{
                            during += _perKeyTime * frame_dur;
                        }
                    }
                }
            }

        }
    }

    //计算动画中的位移
    private function calculateDeformAnimWeight(display:Object,vertices:Array,offset:int = 0):void{

        //spine weight vertices格式:bonecount,boneindex,vx,vy,weight
        var bonePoseArr:Array = display["bonePose"] as Array;
        var bonePoseKV:Dictionary = new Dictionary();
        for(var m:uint = 0;m<bonePoseArr.length;m+=7){
            var matrix:Matrix=new Matrix(bonePoseArr[m+1],bonePoseArr[m+2],bonePoseArr[m+3],
                    bonePoseArr[m+4],bonePoseArr[m+5],bonePoseArr[m+6]);
            bonePoseKV["BoneIndex"+bonePoseArr[m]] = matrix;
        }

        var db_weights:Array=display["weights"] as Array;//db权重
        var db_weights_len:uint=db_weights.length;
        var vertexIndex:uint = 0;
        for(var k:uint = 0 ;k<db_weights_len ;++k){
            var boneCount:uint = uint(db_weights[k]);//骨骼数量
            if(offset<=0){
                var vertex:Point = new Point(vertices[vertexIndex*2],vertices[vertexIndex*2+1]);
                var result:Point = new Point();
                for(var t:uint=0;t<boneCount*2;t+=2){
                    var boneIdx:uint = uint(db_weights[k+t+1]);//骨骼索引
                    var weight:Number =db_weights[k+t+2]; //权重

                    var boneMatrix:Matrix = bonePoseKV["BoneIndex"+boneIdx] as Matrix;
                    boneMatrix.tx =0 ;
                    boneMatrix.ty =0 ;
                    var temp:Point = boneMatrix.transformPoint(vertex);
                    result.x += temp.x*weight;
                    result.y += temp.y*weight;
                }
                vertices[vertexIndex*2] = result.x;
                vertices[vertexIndex*2+1] = result.y;
                ++vertexIndex;
                if(vertexIndex*2+1>=vertices.length){
                    break;
                }
            }
            offset-=boneCount*2;
            k+=boneCount*2;
        }
    }

    private function parseSlotAnimsFrames(spine_attachment:Array,spine_color:Array,frames:Array,db_animSlotObj:Object,type:uint,totalFrame:int){
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

            if(type!=Frame_Type_ColorFrame){
                var displayIndex:int = 0;
                if(frame.hasOwnProperty("displayIndex")){
                    displayIndex = int(frame["displayIndex"]);
                }else if(frame.hasOwnProperty("value")){
                    displayIndex = int(frame["value"]);
                }
                if(displayIndex==-1){
                    if(spine_attachment.length==0 || spine_attachment[spine_attachment.length-1].name!=null){
                        spine_attachment.push({
                            "time":during, "name":null
                        });
                    }
                }else{
                    var attachment:String = _defaultSkinsSlotKV[slotName][displayIndex].name;
                    if(spine_attachment.length==0 || spine_attachment[spine_attachment.length-1].name!=attachment){
                        spine_attachment.push({
                            "time":during, "name":attachment
                        });
                    }
                }
            }

            if(type!=Frame_Type_DisplayFrame){
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
                            "time":during, "color":colorDec,  "curve":curve
                        });
                    }else {
                        spine_color.push({
                            "time": during, "color": colorDec
                        });
                    }
                }
                else
                {
                    if(spine_color.length==0 ||j==frames_len-1|| spine_color[spine_color.length-1].color!="ffffffff"){
                        if(curve){
                            spine_color.push({
                                "time":during, "color":"ffffffff",  "curve":curve
                            });
                        }else {
                            spine_color.push({
                                "time": during, "color": "ffffffff"
                            });
                        }
                    }
                }
            }

            var frame_dur:int = frame.hasOwnProperty("duration") ? int(frame["duration"]) : 1;
            if(frame_dur==0){
                during = _perKeyTime*totalFrame;  //最后一帧
            }else{
                during += _perKeyTime * frame_dur;
            }
            curve = null;
        }
    }

    private function parseSlotAnims(db_animObj:Object,spine_bonesArr:Object,totalFrame:int):void{
        var db_animSlotArr:Array = db_animObj["slot"] as Array;
        var db_animSlotArr_len:uint = db_animSlotArr.length;
        for(var i:uint = 0;i<db_animSlotArr_len;++i){
            var db_animSlotObj:Object = db_animSlotArr[i];

            //spine attachment, color
            var spine_attachment:Array = [];
            var spine_color:Array = [];

            //db frame
            var frames:Array = db_animSlotObj["frame"] as Array;
            if(frames!=null && frames.length>0){//for 5.3及以下
                parseSlotAnimsFrames(spine_attachment,spine_color,frames,db_animSlotObj,Frame_Type_Frame,totalFrame);
            }else{ //for 5.5
                frames = db_animSlotObj["colorFrame"] as Array;
                if(frames!=null && frames.length>0){
                    parseSlotAnimsFrames(spine_attachment,spine_color,frames,db_animSlotObj,Frame_Type_ColorFrame,totalFrame);
                }
                frames = db_animSlotObj["displayFrame"] as Array;
                if(frames!=null && frames.length>0){
                    parseSlotAnimsFrames(spine_attachment,spine_color,frames,db_animSlotObj,Frame_Type_DisplayFrame,totalFrame);
                }
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

    private function parseBoneAnimsFrames(spine_translate:Array,spine_scale:Array,spine_rotate:Array,frames:Array,db_animBoneObj:Object,type:uint,totalFrame):void
    {
        var frames_len:uint = frames.length;
        //time
        var during:Number = 0;
        for(var j:uint = 0 ;j<frames_len;++j){
            var frame:Object = frames[j];
            var curve:Object = null;
            if(j<frames_len-1){
                if(frame.hasOwnProperty("curve")){
                    curve =frame["curve"];
                }else if(frame.hasOwnProperty("tweenEasing")){
                    if(frame["tweenEasing"]==null){
                        curve = "stepped";
                    }
                }
            }
            if(type == Frame_Type_Frame && frame.hasOwnProperty("transform")){
                var transform:Object = frame["transform"];
                if(transform.hasOwnProperty("x")||transform.hasOwnProperty("y")){
                    var px:Number = Number(transform["x"]);
                    var py:Number = -Number(transform["y"]);
                    if(!px) px=0;
                    if(!py) py=0;
                    if(curve){
                        spine_translate.push({
                            "x":px, "y":py, "time":during, "curve":curve
                        });
                    }else{
                        spine_translate.push({
                            "x":px, "y":py, "time":during
                        });
                    }
                }
                else
                {
                    if(spine_translate.length==0 || j==frames_len-1 ||spine_translate[spine_translate.length-1].x!=0||spine_translate[spine_translate.length-1].y!=0)
                    {
                        if(curve){
                            spine_translate.push({
                                "x":0, "y":0,  "time":during,  "curve":curve
                            });
                        }else{
                            spine_translate.push({
                                "x":0,  "y":0,  "time":during
                            });
                        }
                    }else if(j>0){
                        if(curve){
                            spine_translate.push({
                                "x":0, "y":0, "time":during, "curve":curve
                            });
                        }else{
                            spine_translate.push({
                                "x":0, "y":0, "time":during
                            });
                        }
                    }
                }

                if(transform.hasOwnProperty("skX")){
                    var angle:Number = -Number(transform["skX"]);
                    if(!angle) angle=0;
                    if(curve){
                        spine_rotate.push({
                            "angle":angle ,  "time":during, "curve":curve
                        });
                    }else{
                        spine_rotate.push({
                            "angle":angle ,  "time":during
                        });
                    }
                }
                else
                {
                    if(spine_rotate.length==0 || j==frames_len-1 || spine_rotate[spine_rotate.length-1].angle!=0){
                        if(curve){
                            spine_rotate.push({
                                "angle":0 , "time":during, "curve":curve
                            });
                        }else{
                            spine_rotate.push({
                                "angle":0 , "time":during
                            });
                        }
                    }
                    else if(j>0)
                    {
                        if(curve){
                            spine_rotate.push({
                                "angle":0 ,  "time":during, "curve":curve
                            });
                        }else{
                            spine_rotate.push({
                                "angle":0 ,  "time":during
                            });
                        }
                    }
                }

                if(transform.hasOwnProperty("scX")||transform.hasOwnProperty("scY")){
                    var scx:Number = Number(transform["scX"]);
                    var scy:Number = Number(transform["scY"]);
                    if(!scx) scx=1;
                    if(!scy) scy=1;
                    if(curve){
                        spine_scale.push({
                            "x":scx, "y":scy,  "time":during, "curve":curve
                        });
                    }else{
                        spine_scale.push({
                            "x":scx, "y":scy, "time":during
                        });
                    }
                }
                else
                {
                    if(spine_scale.length==0  || j==frames_len-1 || spine_scale[spine_scale.length-1].x!=1 || spine_scale[spine_scale.length-1].y!=1 ){
                        if(curve){
                            spine_scale.push({
                                "x":1,  "y":1, "time":during, "curve":curve
                            });
                        }else{
                            spine_scale.push({
                                "x":1, "y":1, "time":during
                            });
                        }
                    }
                    else if(j>0)
                    {
                        if(curve){
                            spine_scale.push({
                                "x":1, "y":1,  "time":during, "curve":curve
                            });
                        }else{
                            spine_scale.push({
                                "x":1, "y":1, "time":during
                            });
                        }
                    }
                }
            }
            else
            {
                if(type==Frame_Type_TranslateFrame){
                    if(frame.hasOwnProperty("x")||frame.hasOwnProperty("y")){
                        var px:Number = Number(frame["x"]);
                        var py:Number = -Number(frame["y"]);
                        if(!px) px=0;
                        if(!py) py=0;
                        if(curve){
                            spine_translate.push({
                                "x":px, "y":py, "time":during, "curve":curve
                            });
                        }else{
                            spine_translate.push({
                                "x":px, "y":py, "time":during
                            });
                        }
                    }
                    else
                    {
                        if(spine_translate.length==0 || j==frames_len-1 ||spine_translate[spine_translate.length-1].x!=0||spine_translate[spine_translate.length-1].y!=0)
                        {
                            if(curve){
                                spine_translate.push({
                                    "x":0, "y":0,  "time":during,  "curve":curve
                                });
                            }else{
                                spine_translate.push({
                                    "x":0,  "y":0,  "time":during
                                });
                            }
                        }else if(j>0){
                            if(curve){
                                spine_translate.push({
                                    "x":0, "y":0, "time":during, "curve":curve
                                });
                            }else{
                                spine_translate.push({
                                    "x":0, "y":0, "time":during
                                });
                            }
                        }
                    }
                }
                else if(type==Frame_Type_ScaleFrame){
                    if(frame.hasOwnProperty("x")||frame.hasOwnProperty("y")){
                        var px:Number = Number(frame["x"]);
                        var py:Number = Number(frame["y"]);
                        if(!px) px=1;
                        if(!py) py=1;
                        if(curve){
                            spine_scale.push({
                                "x":px, "y":py, "time":during, "curve":curve
                            });
                        }else{
                            spine_scale.push({
                                "x":px, "y":py, "time":during
                            });
                        }
                    }
                    else
                    {
                        if(spine_scale.length==0  || j==frames_len-1 || spine_scale[spine_scale.length-1].x!=1 || spine_scale[spine_scale.length-1].y!=1 ){
                            if(curve){
                                spine_scale.push({
                                    "x":1,  "y":1, "time":during, "curve":curve
                                });
                            }else{
                                spine_scale.push({
                                    "x":1, "y":1, "time":during
                                });
                            }
                        }
                        else if(j>0)
                        {
                            if(curve){
                                spine_scale.push({
                                    "x":1, "y":1,  "time":during, "curve":curve
                                });
                            }else{
                                spine_scale.push({
                                    "x":1, "y":1, "time":during
                                });
                            }
                        }
                    }
                }
                else if(type==Frame_Type_RotateFrame){
                    if(frame.hasOwnProperty("rotate")){
                        var angle:Number = -Number(frame["rotate"]);
                        if(!angle) angle=0;
                        if(curve){
                            spine_rotate.push({
                                "angle":angle ,  "time":during, "curve":curve
                            });
                        }else{
                            spine_rotate.push({
                                "angle":angle ,  "time":during
                            });
                        }
                    }
                    else
                    {
                        if(spine_rotate.length==0 || j==frames_len-1 || spine_rotate[spine_rotate.length-1].angle!=0){
                            if(curve){
                                spine_rotate.push({
                                    "angle":0 , "time":during, "curve":curve
                                });
                            }else{
                                spine_rotate.push({
                                    "angle":0 , "time":during
                                });
                            }
                        }
                        else if(j>0)
                        {
                            if(curve){
                                spine_rotate.push({
                                    "angle":0 ,  "time":during, "curve":curve
                                });
                            }else{
                                spine_rotate.push({
                                    "angle":0 ,  "time":during
                                });
                            }
                        }
                    }
                }
            }

            var frame_dur:int = frame.hasOwnProperty("duration") ? int(frame["duration"]) : 1;
            if(frame_dur==0){
                during = _perKeyTime*totalFrame;  //最后一帧
            }else{
                during += _perKeyTime * frame_dur;
            }
        }
    }

    private function parseBoneAnims(db_animObj:Object,spine_bonesArr:Object,totalFrame:int):void{
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
            if(frames!=null && frames.length>0){ //for 5.3及以下
                parseBoneAnimsFrames(spine_translate,spine_scale,spine_rotate,frames,db_animBoneObj,Frame_Type_Frame,totalFrame);
            }else{
                //for 5.5 及以上
                frames = db_animBoneObj["translateFrame"] as Array;
                parseBoneAnimsFrames(spine_translate,spine_scale,spine_rotate,frames,db_animBoneObj,Frame_Type_TranslateFrame,totalFrame);

                frames = db_animBoneObj["rotateFrame"] as Array;
                parseBoneAnimsFrames(spine_translate,spine_scale,spine_rotate,frames,db_animBoneObj,Frame_Type_RotateFrame,totalFrame);

                frames = db_animBoneObj["scaleFrame"] as Array;
                parseBoneAnimsFrames(spine_translate,spine_scale,spine_rotate,frames,db_animBoneObj,Frame_Type_ScaleFrame,totalFrame);
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
