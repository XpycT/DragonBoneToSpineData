/**
 * Created by zhouzhanglin on 15/11/4.
 */
package skin.black {
import mx.controls.menuClasses.MenuItemRenderer;

public class BlackMenuItemRenderer extends MenuItemRenderer {
    public function BlackMenuItemRenderer() {
        super();
    }

    override protected function updateDisplayList(unscaledWidth:Number,
                                                  unscaledHeight:Number):void
    {
        super.updateDisplayList(unscaledWidth,unscaledHeight);
        graphics.clear();
        if(data is XML && data.@color.length()){
            graphics.beginFill(Number(data.@color), 0.6);
        }
        graphics.drawRect(-1, -1, unscaledWidth+2, unscaledHeight+2);
        graphics.endFill();

    }
}
}
