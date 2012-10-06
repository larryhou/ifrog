package ifrog.utils
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.utils.*;
	
	/**
	 * 闹钟工具类
	 * 设定一个时间，然后执行指定回调
	 * 该工具类只适合精度为秒的计时需要，存在较大误差
	 * 活动自动上下线、boss关冷却等等都比较适合该工具类做定时器
	 * 
	 * @author Larry H.
	 * @createTime 2012/7/24 14:47
	 */
	public class AlarmClock 
	{
		/**
		 * 本地时间与服务器事件的差值：秒
		 */
		public static var TIME_OFFSET:int = 0;
		
		// 闹钟最大序号
		private static var _sequence:uint;
		private static var _timestamp:Number;
		private static var _interval:uint;
		
		private static const _helper:Sprite = new Sprite();
		
		private static const _queue:Array = [];
		private static const _map:Dictionary = new Dictionary();
		
		/**
		 * 当前服务器时间
		 */
		public static function get now():uint
		{
			return (new Date().time / 1000 + TIME_OFFSET) >> 0;
		}
		
		/**
		 * 注册闹钟
		 * @param	time		绝对时间：秒
		 * @param	callback	设定时间到需要执行的回调函数
		 * @return	计时器唯一id，如果要终止倒计时，则需要保存该值
		 */
		public static function register(time:Number, callback:Function, params:Array = null):uint
		{
			var current:Number = new Date().time / 1000 + TIME_OFFSET;
			if (time <= current || callback == null) return 0;
			
			var item:AlarmItem = new AlarmItem(++_sequence, time - TIME_OFFSET, callback, params);
			
			_map[item.id] = item;
			_queue.push(item);
			
			if (!_helper.hasEventListener(Event.ENTER_FRAME))
			{
				_helper.addEventListener(Event.ENTER_FRAME, update);
			}
			
			_interval = 0;
			
			update();
			return item.id;
		}
		
		/**
		 * 检查闹钟
		 * 超低频率执行，高效率
		 */
		static private function update(e:Event = null):void 
		{
			var current:Number = new Date().time;
			if (current - _timestamp < _interval) return;
			
			_timestamp = current;
			
			var approaches:Array = [];
			const APPROACH_TIME:uint = 10 * 1000;
			
			current = current / 1000 >> 0;
			
			var item:AlarmItem;
			for(var i:int = 0; i < _queue.length; i++)
			{
				item = _queue[i];
				if (item.time <= current)
				{
					unregister(item.id);
					
					item.callback.apply(null, item.params);
					item.callback = null;
					
					i--;
					continue;
				}
				
				approaches.push(item.time - current);
			}
			
			approaches.sort(Array.NUMERIC);
			
			var closest:uint = approaches[0] * 1000;
			if (!approaches.length)
			{
				_interval = 0;
			}
			else
			if (closest >= 60 * 1000)
			{
				_interval = closest * 3 / 4 >> 0;
			}
			else
			{
				_interval = closest > APPROACH_TIME? APPROACH_TIME : 1000;
			}
			
			//trace("interval: " + _interval + ", closest: " + closest);
		}
		
		/**
		 * 清除闹钟
		 * @param	id	闹钟唯一标识
		 */
		public static function unregister(id:uint):void
		{
			if (_map[!id]) return;
			
			var item:AlarmItem = _map[id] as AlarmItem;
			
			var index:int = _queue.indexOf(item);
			if (index >= 0) _queue.splice(index, 1);
			
			delete _map[id];
			
			// 效率优化
			if (_queue.length <= 0)
			{
				if (_helper.hasEventListener(Event.ENTER_FRAME))
				{
					_helper.removeEventListener(Event.ENTER_FRAME, update);
				}
			}
		}
		
		/**
		 * 重置闹钟
		 */
		public static function reset():void
		{
			_queue.splice(0, _queue.length);
			for (var key:* in _map) delete _map[key];
			
			if (_helper.hasEventListener(Event.ENTER_FRAME))
			{
				_helper.removeEventListener(Event.ENTER_FRAME, update);
			}
		}
		
	}

}

class AlarmItem
{
	public var id:uint;
	
	public var time:Number;
	
	public var params:Array;
	public var callback:Function;
	
	public var description:String;
	
	// 构造函数
	public function AlarmItem(id:uint, time:Number, callback:Function, params:Array = null)
	{
		this.id = id;
		this.time = time;
		
		this.params = params;
		this.callback = callback;
		
		this.description = new Date(time * 1000).toString();
	}
}