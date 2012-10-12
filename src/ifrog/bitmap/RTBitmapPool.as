package ifrog.bitmap
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	import ifrog.bitmap.core.AbstactPool;
	import ifrog.bitmap.core.FrameInfo;
	import ifrog.bitmap.core.IAdvance;
	import ifrog.bitmap.core.RenderHelper;
	
	/**
	 * 运行时bitmap池
	 * @author Larry H.
	 * @createTime 2012/5/23 18:26
	 */
	public class RTBitmapPool extends AbstactPool implements IAdvance
	{
		private var _frameRate:uint;
		
		private const _queue:Vector.<RTItem> = new Vector.<RTItem>;
		
		/**
		 * 构造函数
		 * create a [RTBitmapPool] object
		 */
		public function RTBitmapPool() 
		{
			_frameRate = 0;
			RenderHelper.register(this);
		}
		
		/**
		 * 处理显示对象
		 * @param	target		显示对象
		 * @param	totalFrames	指定绘制异步帧数
		 * @param	key			缓存键值，pool范围内唯一存在
		 * @param	callback	当所有的缓存制作完成后派发，传参Vector.<FrameInfo>
		 * @return
		 */
		public function process(target:DisplayObject, totalFrames:int, key:String, callback:Function = null):Vector.<FrameInfo>
		{
			if (_map[key]) return _map[key] as Vector.<FrameInfo>;
			
			var item:RTItem = new RTItem(target, totalFrames, key, callback);
			item.map = createLabelMap(target as MovieClip);
			
			_queue.push(item);
			_map[key] = item.frames;
			
			return item.frames;
		}
		
		/**
		 * 刷帧处理
		 */
		public function advance(step:uint):void 
		{
			if (!_queue.length) return;
			
			var item:RTItem;
			var target:DisplayObject;
			
			var container:Sprite = new Sprite();
			
			var data:BitmapData, info:FrameInfo;
			var bounds:Rectangle, matrix:Matrix;
			
			var length:int = _queue.length;
			for (var i:int = 0; i < _queue.length; i++)
			{
				item = _queue[i];
				target = item.target;
				
				if (!target.parent) container.addChild(target);
				bounds = target.getBounds(target.parent);
				
				// 防抖、像素对齐优化
				bounds.width = Math.ceil(bounds.width + bounds.x - (bounds.x >> 0));
				bounds.height = Math.ceil(bounds.height + bounds.y - (bounds.y >> 0));
				bounds.x >>= 0; bounds.y >>= 0;
				
				data = new BitmapData(Math.max(bounds.width, 1), Math.max(bounds.height, 1), true, 0);
				
				// 读取原生matrix, 适应任何变形对象
				matrix = target.transform.matrix;
				matrix.tx = -bounds.x + target.x;
				matrix.ty = -bounds.y + target.y;
				
				info = new FrameInfo(matrix.tx, matrix.ty, data);
				
				item.currentFrame++;
				info.label = item.map[item.currentFrame];
				
				// 获取目标位图数据
				data.draw(target, matrix, null, null, null, true);
				data.lock();
				
				item.frames[item.currentFrame - 1] = info;
				if (item.currentFrame >= item.totalFrames)
				{
					_queue.splice(i--, 1);
					
					item.frames.fixed = true;
					_map[item.key] = item.frames;
					item.callback && item.callback.call(null, item.frames);
					item.dispose();
				}
				
				if (target.parent == container) container.removeChild(target);
			}
			
		}
		
		// getter & setter
		//*************************************************
		/**
		 * 刷新频率
		 */
		public function get frameRate():uint { return _frameRate; }
		public function set frameRate(value:uint):void { }
	}

}


import flash.display.DisplayObject;
import flash.utils.Dictionary;

import ifrog.bitmap.core.FrameInfo;

class RTItem
{
	public var key:String;
	public var target:DisplayObject;
	public var frames:Vector.<FrameInfo>;
	
	public var totalFrames:int;
	public var currentFrame:int;
	
	public var map:Dictionary;
	public var callback:Function;
	
	// 绘制对象
	public function RTItem(target:DisplayObject, totalFrames:int, key:String, callback:Function)
	{
		this.key = key;
		this.target = target;
		this.totalFrames = totalFrames;
		this.frames = new Vector.<FrameInfo>(totalFrames, true);
		this.callback = callback;
	}
	
	public function dispose():void
	{
		this.map = null;
		this.frames = null;
		this.target = null;
		this.callback = null;
	}
}