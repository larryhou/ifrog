package ifrog.bitmap.core
{
	import flash.display.*;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	/**
	 * 位图池基类
	 * @author Larry H.
	 * @createTime 2012/5/23 20:23
	 */
	internal class AbstactPool 
	{
		private var _name:String;
		
		protected const _map:Dictionary = new Dictionary(false);
		
		/**
		 * 构造函数
		 * create a [AbstactPool] object
		 */
		public function AbstactPool()
		{
			_name = String(this) + Math.random().toFixed(6);
		}
		
		/**
		 * 获取动画学列
		 * @param	key
		 * @return
		 */
		public function getMovie(key:String):Vector.<FrameInfo>
		{
			return _map[key];
		}
		
		/**
		 * 释放内存
		 * @param	key	释放内存，如果key不为空则只释放对应的位图数据
		 */
		public function dispose(key:String = null):void
		{
			var info:FrameInfo;
			var frames:Vector.<FrameInfo>;
			
			var map:Dictionary = _map;
			if (key)
			{
				map = new Dictionary(false);
				map[key] = _map[key];
			}
			
			for(var key:String in map)
			{
				frames = map[key];
				while (frames.length > 0)
				{
					info = frames.pop();
					info.data && info.data.dispose();
					info.data = null;
				}
				
				delete map[key];
			}
		}
		
		/**
		 * 构造函数
		 * create a [createLabelMap] object
		 */
		protected static function createLabelMap(target:MovieClip):Dictionary
		{
			var map:Dictionary = new Dictionary();
			if (!target) return map;
			
			var scene:Scene = target.scenes[0];
			for each(var frame:FrameLabel in scene) map[frame.frame] = frame.name;
			return map;
		}
		
		/**
		 * 递归查找容器里面影片剪辑
		 * @param	container	显示对象容器
		 * @return
		 */
		protected static function collectChildren(container:DisplayObjectContainer):Vector.<MovieClip>
		{
			if (!container) return new Vector.<MovieClip>;
			
			var children:Vector.<MovieClip> = new Vector.<MovieClip>;
			
			var target:DisplayObject;
			var length:int = container.numChildren;
			for (var i:int = 0; i < length; i++)
			{
				target = container.getChildAt(i);
				if (target is DisplayObjectContainer)
				{
					if (target is MovieClip) children.push(target);
					children = children.concat(arguments.callee.call(null, target as DisplayObjectContainer));
				}
			}
			
			return children;
		}
		
		/**
		 * 位图池大概占用内存数量：字节
		 */
		public function get size():uint
		{
			var result:uint = 0;
			
			var size:Rectangle;
			for each(var frames:Vector.<FrameInfo> in _map)
			{
				for each(var info:FrameInfo in frames)
				{
					if (!info || !info.data) continue;
					
					size = info.data.rect;
					result += size.width * size.height * 4/*每个像素占用4个字节（32位ARGB）*/;
				}
			}
			
			return result;
		}
		
		/**
		 * 缓存池名字
		 */
		public function get name():String { return _name; }
		public function set name(value:String):void 
		{
			_name = value;
		}
		
	}

}