package ifrog.bitmap.core
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	/**
	 * 帧频节拍器
	 * @author Larry H.
	 * @createTime 2012/5/23 11:08
	 */
	public class RenderHelper 
	{
		private static const _helper:Sprite = new Sprite();
		private static const _map:Dictionary = new Dictionary(false);
		private static const _items:Vector.<IAdvance> = new Vector.<IAdvance>;
		
		private static var _sequence:int;
		private static var _running:Boolean;
		
		/**
		 * 把对象加入渲染中心
		 * @param	item
		 */
		public static function register(item:IAdvance):void
		{
			if (!_map[item])
			{
				_items.push(item);
				_map[item] = new RenderInfo(++_sequence, item.frameRate, getTimer());
			}
			
			if (_items.length > 0 && !_running)
			{
				_running = true;
				_helper.addEventListener(Event.ENTER_FRAME, advance);
			}
		}
		
		/**
		 * 启动渲染计时器
		 * @param	e
		 */
		static private function advance(e:Event):void 
		{
			var timestamp:int = getTimer();
			
			var info:RenderInfo, item:IAdvance;
			for (var i:int = 0; i < _items.length; i++)
			{
				item = _items[i];
				info = _map[item];
				
				// 帧同步
				if (!info.frameRate)
				{
					item.advance(1);
				}
				else
				{
					var step:int = (timestamp - info.timestamp) / info.delta >> 0;
					if (step >= 1)
					{
						item.advance(step);
						info.timestamp += step * info.delta + 0.5 >> 0;
					}
				}
				
				// 更新动态帧率
				if (item.frameRate != info.frameRate)
				{
					info.frameRate = item.frameRate;
					info.delta = 1000 / info.frameRate;
				}
			}
		}
		
		/**
		 * 从渲染中心移除对象
		 * @param	item
		 */
		public static function unregister(item:IAdvance):void
		{
			if (_map[item])
			{
				var index:int = _items.indexOf(item);
				if (index >= 0) _items.splice(index, 1);
				
				delete _map[item];
			}
			
			// 渲染优化
			if (_items.length == 0)
			{
				_running = false;
				_helper.removeEventListener(Event.ENTER_FRAME, advance);
			}
		}
	}

}

class RenderInfo
{
	// 渲染序列号
	public var sequence:int;
	
	// 时间戳
	public var timestamp:int;
	
	// 帧率
	public var frameRate:int;
	
	// 单步渲染时长
	public var delta:Number;
	
	// 构造函数
	public function RenderInfo(sequence:int, frameRate:int, timestamp:int)
	{
		this.sequence = sequence;
		this.frameRate = frameRate;
		this.timestamp = timestamp;
		
		this.delta = 1000 / this.frameRate;
	}
}