package leelibExamples.flvEncoder.webcam.uiEtc
{
    import flash.display.Sprite;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.net.FileReference;
    import flash.utils.ByteArray;
    import flash.events.MouseEvent;
    import flash.events.Event;
    import flash.utils.setTimeout;
    import flash.utils.clearInterval;

    public class SaveDialog extends Sprite
    {
        private var _tf:TextField;
        private var _saveData: ByteArray = null;
        private var _fileName: String = "video";
        private var _closeCallback: Function;
        private var _animStatus: Boolean = true;
        private var _timeoutId:Number;

        public function SaveDialog(message: String, width: int, height: int, closeCallback: Function)
        {
            this._closeCallback = closeCallback;
            this.graphics.beginFill(0xffffff);
            this.graphics.lineStyle(1, 0x0);
            this.graphics.drawRect(0, 0, width, height);
            this.graphics.endFill();

            _tf = new TextField();
            with (_tf) {
                defaultTextFormat = new TextFormat("_sans", 16, 0x5577aa, true, null, null, null, null, "center");
                selectable = mouseEnabled = false;
                height = 40;
                x = 0;
                text = message;
            }
            _tf.width = width;
            _tf.y     = (int)(height / 2) - 20;

            this.addChild(_tf);
            this.addEventListener(MouseEvent.CLICK, this._onSaveClick);
            this.addEventListener(MouseEvent.ROLL_OVER, this._onOver);
			this.addEventListener(MouseEvent.ROLL_OUT, this._onOut);
            this.buttonMode = true;
            this.hide();
        }
        
        private function _onSaveClick(e: *):void
        {
            var fs: FileReference = new FileReference();
            fs.addEventListener(Event.CANCEL, this._closeCallback);
            fs.addEventListener(Event.COMPLETE, this._closeCallback);
            fs.save(this._saveData, this._fileName);
            
            if (this._timeoutId) {
                clearInterval(this._timeoutId);
            }
            
            this.hide();
        }

        public function show(saveData: ByteArray, fileName: String): void
        {
            this._saveData = saveData;
            this._fileName = fileName;
            this.visible  = true;
            
            if (this._timeoutId) {
                clearInterval(this._timeoutId);
            }
            this._animate();
        }

        public function hide(): void
        {
            this.visible = false;
        }
        
        private function _onOver(e:*): void
		{
            _tf.alpha = 0.6;
		}
		private function _onOut(e:*): void
		{
            _tf.alpha = 1.0;
		}
        
        private function _animate():void
        {
            this._animStatus = !this._animStatus;
            if (this._animStatus) {
                this._tf.textColor = 0xFF0000;
            } else {
                this._tf.textColor = 0x5577aa;
            }
            this._timeoutId = setTimeout(this._animate, 1000);
        }
    }
}
