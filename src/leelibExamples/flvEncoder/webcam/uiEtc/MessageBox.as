package leelibExamples.flvEncoder.webcam.uiEtc
{
    import flash.display.Sprite;
    import flash.text.TextField;
    import flash.text.TextFormat;

    public class MessageBox extends Sprite
    {
        private var _tf:TextField;
        private var _width:int = 220;

        public function MessageBox()
        {
            this.graphics.beginFill(0xffffff);
            this.graphics.lineStyle(1, 0x0);
            this.graphics.drawRect(0, 0, this._width, 50);
            this.graphics.endFill();

            _tf = new TextField();
            with (_tf) {
                defaultTextFormat = new TextFormat("_sans", 12, 0x0, true, null, null, null, null, "center");
                width  = this._width;
                height = 18;
                selectable = mouseEnabled = false;
                x = 0;
                y = 16;
            }
            this.addChild(_tf);
            this.hide();
        }

        public function setText(msg: String): void
        {
            _tf.text = msg;
        }

        public function show(msg: String, t: String = 'normal'): void
        {
            if (t == 'error') {
                _tf.defaultTextFormat.color = 0xFF0000;
            } else {
                _tf.defaultTextFormat.color = 0x0;
            }
            this.setText(msg);
            this.visible = true;
        }

        public function hide(): void
        {
            this.visible = false;
        }
    }
}
