package ifrog.bitmap
{
	import flash.display.*;
	import flash.events.EventDispatcher;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import ifrog.bitmap.core.AbstactPool;
	import ifrog.bitmap.core.FrameInfo;
	
	/**
	 * 位图池
	 * @notice	之所以没有做成静态类，是为了bitmap动画分类管理
	 * @author Larry H.
	 * @createTime 2012/5/23 12:08
	 */
	public class BitmapPool extends AbstactPool
	{
		
		/**
		 * 构造函数
		 * create a [BitmapPool] object
		 */
		public function BitmapPool() 
		{
			
		}
		
		/**
		 * 处理影片剪辑
		 * @param	target	影片剪辑
		 * @param	key		缓存键值，pool范围内唯一存在
		 * @return
		 */
		public function process(target:MovieClip, key:String):Vector.<FrameInfo>
		{
			if (!target) return null;
			if (_map[key]) return _map[key] as Vector.<FrameInfo>;
			
			var totalFrames:int = target.totalFrames;
			var dict:Dictionary = createLabelMap(target);
			var frames:Vector.<FrameInfo> = new Vector.<FrameInfo>(totalFrames, true);
			
			var data:BitmapData, matrix:Matrix;	
			var container:Sprite = new Sprite();
			if (!target.parent) container.addChild(target);
			
			var info:FrameInfo, index:int;
			var viewport:Rectangle = new Rectangle();
			for (index = 1; index <= totalFrames; index++)
			{
				target.gotoAndStop(index);
				viewport = viewport.union(target.getBounds(target.parent));
			}
			
			// 防抖、像素对齐优化
			viewport.width = Math.ceil(viewport.width + viewport.x - (viewport.x >> 0));
			viewport.height = Math.ceil(viewport.height + viewport.y - (viewport.y >> 0));
			viewport.x >>= 0; viewport.y >>= 0;
			
			// 读取原生matrix, 适应任何变形对象
			matrix = target.transform.matrix;
			matrix.tx = -viewport.x + target.x;
			matrix.ty = -viewport.y + target.y;
			
			for (index = 1; index <= totalFrames; index++)
			{
				target.gotoAndStop(index);
				
				info = new FrameInfo(matrix.tx, matrix.ty, data);
				info.label = dict[index];
				
				data = new BitmapData(Math.max(viewport.width, 1), Math.max(viewport.height, 1), true, 0);
				data.draw(target, matrix, null, null, null, true);
				
				info.data = data;
				frames[index - 1] = info;
				
				// 帧同步逻辑
				var clips:Vector.<MovieClip> = collectChildren(target);
				for each(var c:MovieClip in clips) c.currentFrame == c.totalFrames? c.gotoAndStop(1) : c.nextFrame();
			}
			
			_map[key] = frames;
			if (target.parent == container) container.removeChild(target);
			
			target.play();
			return frames;
		}
		
	}

}