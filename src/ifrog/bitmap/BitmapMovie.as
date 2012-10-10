package ifrog.bitmap
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import ifrog.bitmap.core.FrameInfo;
	import ifrog.bitmap.core.IAdvance;
	import ifrog.bitmap.core.RenderHelper;
	
	import mx.core.IFlexAsset;
	
	/**
	 * 单次循环播放完成时派发
	 */
	[Event(name = "change", type = "flash.events.Event")]
	
	/**
	 * 所有循环播放完成时派发
	 */
	[Event(name = "complete", type = "flash.events.Event")]
	
	/**
	 * 位图影片
	 * @author Larry H.
	 * @createTime 2012/5/23 11:30
	 */
	public class BitmapMovie extends Bitmap implements IAdvance
	{
		private var _frameRate:uint;
		private var _frames:Vector.<FrameInfo>;
		
		private var _loop:uint;
		private var _numloop:uint;
		
		private var _playing:Boolean;
		
		private var _totalFrames:uint;
		private var _currentFrame:uint;
		
		private var _map:Dictionary;
		
		private var _offsetX:Number;
		private var _offsetY:Number;
		
		private var _smoothing:Boolean;
		
		private var _width:Number;
		private var _height:Number;
		
		/**
		 * 构造函数
		 * create a [BitmapMovie] object
		 */
		public function BitmapMovie(frames:Vector.<FrameInfo> = null)
		{
			_loop = 0;
			_playing = false;
			
			_width = _height = 0;
			_offsetX = _offsetY = 0;
			
			this.frameRate = 12;
			this.frames = frames;
		}
		
		// 刷帧处理
		public function advance(step:uint):void
		{
			var frame:int = _currentFrame + step;
			if (frame > _totalFrames)
			{
				frame = 1;
				_numloop++;
				
				dispatchEvent(new Event(Event.CHANGE, true));
				
				if (_numloop >= _loop && _loop > 0)
				{
					stop();
					dispatchEvent(new Event(Event.COMPLETE, true));
				}
			}
			
			gotoAndStop(frame);
		}
		
		/**
		 * 播放动画
		 * @param	resume	是否接着上一帧继续播放
		 */
		public function play(resume:Boolean = false):void
		{
			_playing = true;
			if (!resume)
			{
				_numloop = 0;
				gotoAndStop(1);
			}
			
			_totalFrames > 1 && RenderHelper.register(this);
		}
		
		/**
		 * 跳转到指定帧播放
		 * @param	frame	目标帧，接受帧标签以及帧号
		 */
		public function gotoAndPlay(frame:Object):void
		{
			gotoAndStop(frame);
			
			play(false);
		}
		
		/**
		 * 上一帧
		 * @param	loop	是否自动跳转到最后一帧
		 */
		public function prevFrame(loop:Boolean = false):void
		{
			var frame:int = _currentFrame - 1;
			if (frame <= 0)
			{
				frame = loop? _totalFrames : 0;
			}
			
			gotoAndStop(frame);
		}
		
		/**
		 * 下一帧
		 * @param	loop	是否自动跳转到第一帧
		 */
		public function nextFrame(loop:Boolean = false):void
		{
			var frame:int = _currentFrame + 1;
			if (frame >= _totalFrames)
			{
				frame = loop? 0 : _totalFrames;
			}
			
			gotoAndStop(frame);
		}
		
		/**
		 * 跳转到指定帧
		 * @param	frame	目标帧，接受帧标签以及帧号
		 */
		public function gotoAndStop(frame:Object):void
		{
			// 运行时draw需要动态更新总帧
			if (_totalFrames != _frames.length)
			{
				_totalFrames = _frames.length;
			}
			
			if (frame is String) frame = _map[frame];
			_currentFrame = Math.min(Math.max(int(frame), 1), _totalFrames);
			
			var info:FrameInfo = _frames[_currentFrame - 1];
			if (!info) return;
			
			// 效率优化
			if(super.bitmapData != info.data)
			{
				super.bitmapData = info.data;
				super.smoothing = _smoothing;
			}
			
			positionUpdate();
		}
		
		/**
		 * 更新位图坐标
		 */		
		private function positionUpdate():void
		{
			if(!_frames || _frames.length <= _currentFrame) return;
			
			var info:FrameInfo = _frames[_currentFrame - 1];
			if(!info) return;
			
			// 分类进行位置调整，效率优化
			if(!this.scaleX && !this.scaleY)
			{
				super.x = _offsetX - info.x;
				super.y = _offsetY - info.y;
				
				return;
			}
			
			var pivot:Point = new Point(info.x * this.scaleX, info.y * this.scaleY);
			
			if(this.rotation)
			{
				var rot:Number = this.rotation / 180 * Math.PI;			
				var slop:Number = Math.atan2(pivot.y, pivot.x);
				var radius:Number = pivot.length;
				
				super.x = _offsetX - pivot.x - radius * (Math.cos(slop + rot) - Math.cos(slop));
				super.y = _offsetY - pivot.y - radius * (Math.sin(slop + rot) - Math.sin(slop));
			}
			else
			{
				super.x = _offsetX - pivot.x;
				super.y = _offsetY - pivot.y;
			}
		}
		
		/**
		 * 停止播放动画
		 */
		public function stop():void
		{
			_playing = false;
			RenderHelper.unregister(this);
		}
		
		// getter & setter
		//*************************************************
		// 禁止外部操作数据
		override public function set bitmapData(value:BitmapData):void { }
		
		/**
		 * 帧频, 支持动态修改
		 */
		public function get frameRate():uint { return _frameRate; }
		public function set frameRate(value:uint):void 
		{
			_frameRate = value;
		}	
		
		/**
		 * 获取当前动画的矩形边界
		 */
		public function get bounds():Rectangle
		{
			if (bitmapData) return bitmapData.getColorBoundsRect(0xFF000000, 0, false);
			return new Rectangle();
		}
		
		/**
		 * 是否正在播放
		 */
		public function get playing():Boolean { return _playing; }
		
		/**
		 * 循环播放次数
		 * @notice	如果为0，则不限次循环播放
		 * @default 0
		 */
		public function get loop():uint { return _loop; }
		public function set loop(value:uint):void 
		{
			_loop = value;
		}
		
		/**
		 * 设置帧序列
		 */
		public function get frames():Vector.<FrameInfo> { return _frames; }
		public function set frames(value:Vector.<FrameInfo>):void 
		{
			_frames = value || new Vector.<FrameInfo>;
			
			_currentFrame = 1;
			_totalFrames = _frames.length;
			
			_map = new Dictionary(false);
			
			//NOTE 如果是运行时draw，则这里不更新
			var bounds:Rectangle = new Rectangle();
			for each(var fr:FrameInfo in _frames)
			{
				if (fr) bounds = bounds.union(fr.data.rect);
			}
			
			_width = bounds.width;
			_height = bounds.height;
		}
		
		/**
		 * 总帧数
		 */
		public function get totalFrames():uint { return _totalFrames; }
		
		/**
		 * 当前帧
		 */
		public function get currentFrame():uint { return _currentFrame; }
		public function set currentFrame(value:uint):void 
		{
			gotoAndStop(value);
		}
		
		/**
		 * 更新坐标
		 */
		override public function get x():Number { return _offsetX; }
		override public function set x(value:Number):void 
		{
			_offsetX = value;
			positionUpdate();
		}
		
		/**
		 * 更新坐标
		 */
		override public function get y():Number { return _offsetY; }
		override public function set y(value:Number):void 
		{
			_offsetY = value;
			positionUpdate();
		}
		
		override public function set scaleX(value:Number):void
		{
			super.scaleX = value;
			positionUpdate();
		}
		
		override public function set scaleY(value:Number):void
		{
			super.scaleY = value;
			positionUpdate();
		}
		
		override public function set rotation(value:Number):void
		{
			super.rotation = value;
			positionUpdate();
		}
		
		/**
		 * 是否平滑显示
		 */
		override public function get smoothing():Boolean { return _smoothing; }
		override public function set smoothing(value:Boolean):void 
		{
			super.smoothing = _smoothing = value;
		}
		
		/**
		 * 影片宽度
		 * @notice	
		 */
		override public function get width():Number { return _width? _width : super.width; }
		override public function set width(value:Number):void 
		{
			_width = Math.max(value, 0);
		}
		
		/**
		 * 影片高度
		 */
		override public function get height():Number { return _height? _height : super.height; }
		override public function set height(value:Number):void 
		{
			_height = Math.max(value, 0);
		}
	}
}