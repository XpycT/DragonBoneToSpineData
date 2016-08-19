/**
 * Created by zhouzhanglin on 16/8/19.
 */
package parse {
import data.*;

public class ParseJson {
    public function ParseJson() {
    }

    private var _armatureData:ArmatureData;

    /**
     * 解析动画json
     * @param json
     */
    public function parseAnimJson(json:String):void
    {
        _armatureData = new ArmatureData();
        var jsonObj:Object = JSON.parse(json);
        trace(jsonObj.name);
    }
}
}
