package ifrog.utils
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.utils.Dictionary;
	
	/**
	 * 闹钟工具类
	 * 设定在一个未来时间执行指定回调，只适合最小精度为秒的计时需要
	 * 
	 * @author larryhou
	 * @createTime 2012/7/24 14:47
	 */
	public class AlarmClock 
	{
		// 闹钟最大序号
		private var _sequence:uint;
		private var _timestamp:Number;
		
		private var _queue:Array;
		private var _interval:uint;		
		private var _helper:Sprite;
		
		private var _map:Dictionary;
		
		private var _timeOffset:int;
		private var _suspended:Boolean;
		
		/**
		 * 构造函数
		 * create a [AlarmClock] object
		 */
		public function AlarmClock()
		{
			_queue = [];
			_helper = new Sprite();
			_map = new Dictionary(false);
			
			_suspended = false;
		}
		
		/**
		 * 注册闹钟
		 * @param	time		绝对时间：秒
		 * @param	callback	设定时间到需要执行的回调函数
		 * @return	计时器唯一id，如果要终止倒计时，则需要保存该值
		 */
		public function register(time:Number, callback:Function, params:Array = null):uint
		{
			var current:Number = new Date().time / 1000 + _timeOffset;
			if (time <= current || callback == null)
			{
				callback && callback.apply(null, params); return 0;
			}
			
			var item:AlarmItem = new AlarmItem(++_sequence, time - _timeOffset, callback, params);
			
			_map[item.id] = item;
			_queue.push(item);
			
			if (!_helper.hasEventListener(Event.ENTER_FRAME) && !_suspended)
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
		private function update(e:Event = null):void 
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
		public function unregister(id:uint):void
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
		 * 重置闹钟，该方法会清空所有计时项目
		 */
		public function reset():void
		{
			_queue.splice(0, _queue.length);
			for (var key:* in _map) delete _map[key];
			
			if (_helper.hasEventListener(Event.ENTER_FRAME))
			{
				_helper.removeEventListener(Event.ENTER_FRAME, update);
			}
		}

		/**
		 * 目标时间与本地系统时间差值
		 * @default 0
		 */		
		public function get timeOffset():int { return _timeOffset; }
		public function set timeOffset(value:int):void
		{
			_timeOffset = value;
		}	
		
		/**
		 * 当前目标时间
		 */
		public function get time():uint { return (new Date().time / 1000 + _timeOffset) >> 0; }

		/**
		 * 是否暂停计时器
		 * @default false
		 */		
		public function get suspended():Boolean	{ return _suspended; }
		public function set suspended(value:Boolean):void
		{
			_suspended = value;
			if (_suspended)
			{
				if (_helper.hasEventListener(Event.ENTER_FRAME))
				{
					_helper.removeEventListener(Event.ENTER_FRAME, update);
				}
			}
			else
			if (_queue.length)
			{
				_helper.addEventListener(Event.ENTER_FRAME, update);
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