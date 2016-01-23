package leelibExamples.flvEncoder.webcam
{
    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.display.BitmapData;
    import flash.text.TextField;
    import flash.media.Camera;
    import flash.media.Video;
    import flash.media.Microphone;
    import flash.text.TextFieldAutoSize;
    import leelibExamples.flvEncoder.webcam.uiEtc.States;
    import leelibExamples.flvEncoder.webcam.uiEtc.RecordButton;
    import leelibExamples.flvEncoder.webcam.uiEtc.MessageBox;
    import leelibExamples.flvEncoder.webcam.uiEtc.SaveDialog;
    import flash.geom.Matrix;
    import flash.geom.Rectangle;
    import leelib.util.flvEncoder.FlvEncoder;
    import leelib.util.flvEncoder.MicRecorderUtil;
    import leelib.util.flvEncoder.VideoPayloadMakerAlchemy;
    import leelib.util.flvEncoder.ByteArrayFlvEncoder;
    import flash.text.*;
    import flash.utils.ByteArray;
    import flash.utils.setTimeout;
    import flash.utils.getTimer;
    import flash.utils.clearInterval;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.StatusEvent;
    import flash.events.ActivityEvent;
    import flash.events.IOErrorEvent;
    import flash.events.ProgressEvent;
    import flash.events.SecurityErrorEvent;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.external.*;

    public class WebcamRealTimeApp extends Sprite 
    {
        private const OUTPUT_WIDTH:Number  = 320;
        private const OUTPUT_HEIGHT:Number = 240;
        private const CAM_WIDTH:Number     = 320;
        private const CAM_HEIGHT:Number    = 240;

        private var _flv_framerate:int        = 10;
        private var _flv_autostop_timeout:int = 15;    // автоматическая остановка записи через N секунд
        private var _autoStopOnly:Boolean     = false; // использовать подсказки о ходе записи и загрузки средствами flash(иначе js)
        private var _useInlineGui:Boolean     = true;  // использовать подсказки о ходе записи и загрузки средствами flash(иначе js)
        private var _debug:Boolean            = false; // использовать подсказки о ходе записи и загрузки средствами flash(иначе js)
        private var _uploadToServer:Boolean   = false;

        private var _params:Object;
        private var _flvEncoder:FlvEncoder;

        private var _output:Sprite;
        private var _btnRecord:RecordButton;
        private var _tfTime:TextField;
        private var _tfSize:TextField;
        private var _waitForUpload: MessageBox;
        private var _saveDialog: SaveDialog;

        private var _cam:Camera;
        private var _video:Video;
        private var _micUtil:MicRecorderUtil;

        private var _encodeFrameNum:int;
        private var _startTime:Number;
        private var _videoTimeOffset:int;
        private var _bitmaps:Array;
        private var _audioFrameIndices:Array;
        private var _audioCursor:int;
        private var _micBytesPerSecond:int;
        private var _recordId:Number;
        private var _timeoutId:Number;
        private var _state:String = "waiting";

        public function WebcamRealTimeApp()
        {
            super();

            // загрузка flashvars
            this._params = this.stage.loaderInfo.parameters;
            
            if (!this._params.hasOwnProperty('uploadUrl')
                || !this._params.hasOwnProperty('clientId')
                || !this._params.hasOwnProperty('token')
            ) {
                var tf:TextField = new TextField();
                tf.autoSize = TextFieldAutoSize.LEFT;
                tf.text = "Неверные параметры запуска!";
                tf.x = 15;
                tf.y = 15;
                this.addChild(t);
                return;
            }
            
            if (this._params.hasOwnProperty('recordTimeout')) {
                this._flv_autostop_timeout = int(this._params['recordTimeout']);
            }
            if (this._params.hasOwnProperty('autoStopOnly')) {
                this._autoStopOnly = true;
            }
            if (this._params.hasOwnProperty('framerate')) {
                this._flv_framerate = int(this._params['framerate']);
            }
            if (this._params.hasOwnProperty('useGuiHelper')) {
                this._useInlineGui = false;
            }
            if (this._params.hasOwnProperty('debug')) {
                this._debug = true;
            }
            if (this._params.hasOwnProperty('uploadToServer')) {
                this._uploadToServer = true;
            }
            // ================================
            
            this.stage.align = StageAlign.TOP_LEFT;
            this.stage.scaleMode = StageScaleMode.NO_SCALE;
            this.stage.frameRate = 30;

            this.graphics.beginFill(0xE5E5E5);
            this.graphics.drawRect(0, 0, this.stage.stageWidth, this.stage.stageHeight);
            this.graphics.endFill();
            
            if (!(Camera.getCamera()) || !(Microphone.getMicrophone())) {
                var t:TextField = new TextField();
                t.autoSize = TextFieldAutoSize.LEFT;
                t.text = "Пожалуйста, подключите камеру и микрофон.";
                t.x = 15;
                t.y = 15;
                this.addChild(t);
                return;
            }
            
            this._output = new Sprite();
            this._output.graphics.beginFill(0xE5E5E5);
            this._output.graphics.drawRect(0, 0, this.OUTPUT_WIDTH, this.OUTPUT_HEIGHT);
            this._output.graphics.endFill();
            this._output.x = 0;
            this._output.y = 0;
            this.addChild(this._output);
            
            this._btnRecord = new RecordButton();
            this._btnRecord.addEventListener(MouseEvent.CLICK, this.onBtnRecClick);
            this._btnRecord.x = 10;
            this._btnRecord.y = ((this._output.y + this._output.height) + 15);
            this.addChild(this._btnRecord);
            
            this._tfSize = new TextField();
            _local_2 = this._tfSize;
            with (_local_2) {
                defaultTextFormat = new TextFormat("_sans", 10, 0, false, null, null, null, null, "right");
                width = 100;
                height = 20;
                selectable = false;
                x = this._btnRecord.x + this._btnRecord.width + 20;
                y = this._btnRecord.y + 2;
            }
            this.addChild(this._tfSize);
            
            this._tfTime = new TextField();
            var _local_2:TextField = this._tfTime;
            with (_local_2) {
                defaultTextFormat = new TextFormat("_sans", 12, 0xCC0000, true, null, null, null, null, "right");
                width = 100;
                height = 20;
                selectable = false;
                x = OUTPUT_WIDTH - 100;
                y = this._btnRecord.y;
            }
            this.addChild(this._tfTime);
            
            if (this._useInlineGui) {
                this._waitForUpload = new MessageBox();
                with (this._waitForUpload) {
                    x = OUTPUT_WIDTH / 2 - 110;
                    y = OUTPUT_HEIGHT / 2;
                }
                this.addChild(this._waitForUpload);
            }
            
            if (!this._uploadToServer) {
                this._saveDialog = new SaveDialog(">>> Нажмите для сохранения <<<", OUTPUT_WIDTH - 1, OUTPUT_HEIGHT, onSaveDialogClose);
                this.addChild(this._saveDialog);
            }

            this._video = new Video();
            this._video.smoothing = false;
            this._video.width = this.OUTPUT_WIDTH;
            this._video.height = this.OUTPUT_HEIGHT;
            this._output.addChild(this._video);

            this._cam = Camera.getCamera();
            this._cam.setMode(this.CAM_WIDTH, this.CAM_HEIGHT, 30);
            this._cam.setQuality(0, 100);
            
            var mic:Microphone = Microphone.getMicrophone();
            mic.setSilenceLevel(0, int.MAX_VALUE);
            mic.gain = 66;
            mic.rate = 44;
            
            this._micUtil = new MicRecorderUtil(mic);
            this._micBytesPerSecond = (44100 * 4);
            
            this.setState(States.WAITING_FOR_WEBCAM);
        }

        private function onCamStatus(_arg_1:StatusEvent):void
        {
            addLog(_arg_1.code);
            if (_arg_1.code == "Camera.Unmuted"){
                this._cam.removeEventListener(StatusEvent.STATUS, this.onCamStatus);
                this._cam.removeEventListener(ActivityEvent.ACTIVITY, this.onCamActivity);
                this.setState(States.WAITING_FOR_RECORD);
            };
        }

        private function onCamActivity(_arg_1:ActivityEvent):void
        {
            addLog("onCamActivity", _arg_1.type, _arg_1.activating);
            this._cam.removeEventListener(StatusEvent.STATUS, this.onCamStatus);
            this._cam.removeEventListener(ActivityEvent.ACTIVITY, this.onCamActivity);
            this.setState(States.WAITING_FOR_RECORD);
        }

        private function startRecording():void
        {
            if (this._flvEncoder){
                this._flvEncoder.kill();
            };
            this.instantiateFlvEncoder();
            
            this._flvEncoder.setVideoProperties(this.OUTPUT_WIDTH, this.OUTPUT_HEIGHT, VideoPayloadMakerAlchemy);
            this._flvEncoder.setAudioProperties(FlvEncoder.SAMPLERATE_44KHZ, true, false, true);
            
            this.addMessage("Запись");
            this._bitmaps = [];
            this._audioFrameIndices = [];
            this._encodeFrameNum = 0;
            this._videoTimeOffset = 0;
            this._startTime = getTimer();
            this._audioCursor = 0;
            this._flvEncoder.start();
            this._micUtil.record();
            this.onRecordInterval();
            
            if (this._flv_autostop_timeout > 0) {
                this._timeoutId = setTimeout(this.onTimeoutExpire, this._flv_autostop_timeout * 1000);
            }
        }
        
        private function onTimeoutExpire():void
        {
            this.setState(States.SAVING);
        }

        private function encodeNext():void
        {
            var _local_3:int;
            var _local_4:int;
            var _local_5:int;
            var _local_6:int;
            var _local_7:int;
            var _local_8:int;
            var _local_9:Number;
            var _local_10:int;
            var _local_11:Matrix;
            var _local_12:int;
            var _local_13:int;
            var _local_14:ByteArray;
            var _local_15:Number;
            var _local_16:String;
            var _local_1:ByteArray = new ByteArray();
            var _local_2:BitmapData = this._bitmaps[this._encodeFrameNum];
            
            if (this._encodeFrameNum > 0){
                this._audioCursor = (this._audioCursor + this._flvEncoder.audioFrameSize);
                _local_3 = this._audioCursor;
                _local_4 = this._flvEncoder.audioFrameSize;
                _local_5 = (this._audioFrameIndices[this._encodeFrameNum] - (_local_3 + _local_4));
                if ((_local_3 + _local_4) < this._micUtil.byteArray.length){
                    _local_1.writeBytes(this._micUtil.byteArray, _local_3, _local_4);
                } else {
                    if (_local_3 >= this._micUtil.byteArray.length){
                        addLog("WARNING: AUDIOCURSOR IS BEYOND MIC BYTES - WRITING 0's");
                    } else {
                        addLog("WARNING: NOT ENOUGH AUDIO TO WRITE FULL AUDIO FRAME");
                        _local_7 = ((this._micUtil.byteArray.length - 1) - this._audioCursor);
                        _local_8 = (this._flvEncoder.audioFrameSize - _local_7);
                        _local_1.writeBytes(this._micUtil.byteArray, _local_3, _local_7);
                        _local_1.length = (_local_1.length + _local_8);
                    };
                };
                _local_6 = ((44100 * 4) / (this._flv_framerate / 2));
                if (Math.abs(_local_5) > _local_6){
                    _local_9 = (_local_5 * 0.75);
                    _local_9 = (int((_local_9 / 4)) * 4);
                    this._audioCursor = (this._audioCursor + _local_9);
                    _local_10 = int(((_local_9 / (44100 * 4)) * 1000));
                    this.addMessage((((("[" + this.makeTimeStamp(this._encodeFrameNum)) + "] audio resync ") + _local_10) + "ms"));
                };
                if (this._micUtil.byteArray.length > (this._micBytesPerSecond * 3)){
                    this._micUtil.shift(this._micBytesPerSecond);
                    this._audioCursor = (this._audioCursor - this._micBytesPerSecond);
                    _local_12 = Math.max(((this._audioFrameIndices.length - (this._flv_framerate * 2)) - 2), 0);
                    _local_12 = 0;
                    _local_13 = _local_12;
                    while (_local_13 < this._audioFrameIndices.length) {
                        this._audioFrameIndices[_local_13] = (this._audioFrameIndices[_local_13] - this._micBytesPerSecond);
                        _local_13++;
                    };
                };
            } else {
                _local_14 = new ByteArray();
                _local_14.length = this._flvEncoder.audioFrameSize;
                _local_1.writeBytes(_local_14);
            };

            this._flvEncoder.addFrame(_local_2, _local_1);
            
            this._bitmaps[this._encodeFrameNum].dispose();
            if ((this._encodeFrameNum % this._flv_framerate) == 0){
                _local_15 = (this.getFlvSize() / (0x0400 * 0x0400));
                _local_15 = (int((_local_15 * 10)) / 10);
                _local_16 = _local_15.toString();
                if ((_local_15 % 1) == 0){
                    _local_16 = (_local_16 + ".0");
                };
                this._tfSize.text = (_local_15 + "MB");
            };
            this._encodeFrameNum++;
        }

        private function onRecordInterval():void
        {
            var _local_6:int;
            var _local_7:Matrix;
            var _local_1:BitmapData = new BitmapData(this.OUTPUT_WIDTH, this.OUTPUT_HEIGHT, false, 0);
            _local_1.draw(this._output);
            this._bitmaps.push(_local_1);
            this._audioFrameIndices.push(this._micUtil.byteArray.length);
            this._tfTime.text = this.makeTimeStamp(this._bitmaps.length);

            if (this._bitmaps.length > 5) {
                this.encodeNext();
            }

            var _local_2:int = ((getTimer() - this._startTime) - this._videoTimeOffset);
            var _local_3:int = ((this._bitmaps.length / this._flv_framerate) * 1000);
            var _local_4:int = (_local_3 - _local_2);
            if (_local_4 < 10) {
                _local_6 = (10 - _local_4);
                this._videoTimeOffset = (this._videoTimeOffset + _local_6);
                this.addMessage((((((("[" + this.makeTimeStamp((this._bitmaps.length - 1))) + "] video resync ") + _local_6) + "ms (total: ") + this._videoTimeOffset) + "ms)"));
            }
            this._recordId = setTimeout(this.onRecordInterval, Math.max(_local_4, 10));
        }

        private function onBtnRecClick(e:*):void
        {
            if (this._state == States.WAITING_FOR_RECORD) {
                this.setState(States.RECORDING);
            } else {
                if (this._state == States.RECORDING && !this._autoStopOnly) {
                    this.setState(States.SAVING);
                }
            }
        }
        
        private function onSaveDialogClose(e:*):void
        {
            this.setState(States.WAITING_FOR_RECORD);
        }

        private function addMessage(msg:String):void
        {
            this.addLog("addMessage: " + msg);
        }

        private function addLog(... args):void
        {
            if (this._debug) {
                flash.external.ExternalInterface.call('vdAddLog', args);
            }
        }

        private function setState(state:String):void
        {
            this._state = state;
            switch (this._state){
                case States.WAITING_FOR_WEBCAM:
                    this._cam.addEventListener(StatusEvent.STATUS, this.onCamStatus);
                    this._cam.addEventListener(ActivityEvent.ACTIVITY, this.onCamActivity);
                    this._video.attachCamera(this._cam);
                    break;
                case States.WAITING_FOR_RECORD:
                    this._video.alpha = 1;
                    this._video.attachCamera(this._cam);
                    this._btnRecord.visible = true;
                    this._btnRecord.setActive(true);
                    this._btnRecord.showRecord();
                    this._tfTime.text = "00:00:00";
                    this._tfSize.text = "0MB";
                    break;
                case States.RECORDING:
                    if (this._autoStopOnly) {
                        this._btnRecord.setActive(false);
                    } else {
                        this._btnRecord.showStop();
                    }
                    this.startRecording();
                    break;
                case States.SAVING:
                    this._btnRecord.setActive(false);
                    clearInterval(this._recordId);
                    clearInterval(this._timeoutId);
                    this._video.alpha = 0.5;
                    while (this._encodeFrameNum < (this._bitmaps.length - 1)) {
                        this.encodeNext();
                    }
                    this._micUtil.stop();
                    this.saveFlv();
                    break;
            };
        }

        private function makeTimeStamp(_arg_1:int):String
        {
            var _local_2:int = int((_arg_1 / this._flv_framerate));
            var _local_3:String = int((_local_2 / 60)).toString();
            if (_local_3.length == 1){
                _local_3 = ("0" + _local_3);
            };
            var _local_4:String = (_local_2 % 60).toString();
            if (_local_4.length == 1){
                _local_4 = ("0" + _local_4);
            };
            var _local_5:String = (_arg_1 % this._flv_framerate).toString();
            if (_local_5.length == 1){
                _local_5 = ("0" + _local_5);
            };
            return (((((_local_3 + ":") + _local_4) + ":") + _local_5));
        }

        protected function instantiateFlvEncoder():void
        {
            this._flvEncoder = new ByteArrayFlvEncoder(this._flv_framerate);
        }
        
        protected function getFlvSize():Number
        {
            return (ByteArrayFlvEncoder(this._flvEncoder).byteArray.length);
        }

        protected function saveFlv():void
        {
            this.addMessage("Stopped.");
            this._flvEncoder.updateDurationMetadata();
            var flvSrc:ByteArrayFlvEncoder = (this._flvEncoder as ByteArrayFlvEncoder);
            var flvData:ByteArray = flvSrc.byteArray;

            if (_uploadToServer) {
                uploadToServer(flvData);
            } else {
                this._saveDialog.show(flvData, "contact-" + this._params['clientId'] + ".flv");
            }
        }

        private function onStartUpload():void
        {
            flash.external.ExternalInterface.call('vdOnUploadStart');
            if (this._useInlineGui) {
                this._waitForUpload.show('Сохранение');
            }
        }
        
        private function hideSaveDialog():void
        {
            if (this._useInlineGui) {
                this._waitForUpload.hide();
            }
            this.setState(States.WAITING_FOR_RECORD);
        }

        private function uploadToServer(flvData: ByteArray):void
        {
            onStartUpload();
            
            var req: URLRequest = new URLRequest();
            req.url         = this._params['uploadUrl'] + '&clientId=' + this._params['clientId'] + '&token=' + this._params['token'];
            req.method      = URLRequestMethod.POST;
            req.contentType = 'application/octet-stream';
            req.data        = flvData;

            var loader: URLLoader = new URLLoader();
            loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
            loader.addEventListener(IOErrorEvent.IO_ERROR, onUploadError);
            loader.addEventListener(ProgressEvent.PROGRESS, onUploadProgress);
            loader.addEventListener(Event.COMPLETE, onUploadComplete);

            try {
                loader.load(req);
            } catch (error: SecurityError) {
                addLog("A SecurityError has occurred.");
                flash.external.ExternalInterface.call('vdOnUploadError', 'SecurityError');
                hideSaveDialog();
            }
        }

        private function onSecurityError(e: Event):void
        {
            addLog("onSecurityError:", e);
            flash.external.ExternalInterface.call('vdOnUploadError', e);
            hideSaveDialog();
        }

        private function onUploadError(e: Event):void
        {
            addLog("onUploadError:", e);
            flash.external.ExternalInterface.call('vdOnUploadError', e);
            hideSaveDialog();
        }

        private function onUploadProgress(e: ProgressEvent):void
        {
            var p:int = int(e.bytesLoaded / e.bytesTotal * 100);
            addLog("onUploadProgress:", e, p + "%");
            flash.external.ExternalInterface.call('vdOnUploadProgress', p);
            
            if (this._useInlineGui) {
                this._waitForUpload.setText('Сохранение: ' + p + '%');
            }
        }

        private function onUploadComplete(e: Event):void
        {
            var loader:URLLoader = URLLoader(e.target);
            addLog("onUploadComplete: " + loader.data, e);
            
            flash.external.ExternalInterface.call('vdOnUploadComplete', loader.data);

            if (this._useInlineGui) {
                var obj: Object;
                var jsonError: Boolean = false;
                
                try {
                    obj = JSON.parse(loader.data);
                } catch (e: Error) {
                    jsonError = true;
                }
                
                if (jsonError || obj == null || !obj.hasOwnProperty('errorCode') || (obj['errorCode'] > 0)) {
                    if (this._useInlineGui) {
                        this._waitForUpload.hide();
                    }
                    this._waitForUpload.show('Внутренняя ошибка', 'error');
                } else {
                    this._waitForUpload.setText('Запись успешно сохранена!');
                }
            }
            setTimeout(hideSaveDialog, 3000);
        }
    }
}
