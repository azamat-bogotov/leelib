package leelibExamples.flvEncoder.webcam.uiEtc
{
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;

	public class RecordButton extends Sprite
	{
		private var _tf:TextField;
        private var _active:Boolean = true;

		public function RecordButton()
		{
			this.graphics.beginFill(0xffffff);
			this.graphics.lineStyle(1, 0x0);
			this.graphics.drawRect(0,0,120,20);
			this.graphics.endFill();

			_tf = new TextField();
			with (_tf)
			{
				defaultTextFormat = new TextFormat("_sans", 12, 0x0, true, null,null,null,null,"center");
				width = 120;
				height = 18;
				selectable = mouseEnabled = false;
				x = 0;
				y = 0;
			}
			this.addChild(_tf);

			this.addEventListener(MouseEvent.ROLL_OVER, onOver);
			this.addEventListener(MouseEvent.ROLL_OUT, onOut);
			this.buttonMode = true;

			showRecord();
		}

		public function showRecord():void
		{
			_tf.text = "Начать запись";
		}

		public function showStop():void
		{
			_tf.text = "Стоп";
		}
        
        public function setActive(active: Boolean):void
		{
            if (this._active == active) {
                return;
            }

            this._active    = active;
            this.buttonMode = this._active;
            if (active) {
                this.alpha = 1.0;
            } else {
                this.alpha = 0.4;
            }
		}

		private function onOver(e:*):void
		{
            if (this._active) {
                this.alpha = 0.66;
            }
		}
		private function onOut(e:*):void
		{
            if (this._active) {
                this.alpha = 1.0;
            }
		}
	}
}
