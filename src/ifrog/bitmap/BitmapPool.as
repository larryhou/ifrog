package ifrog.bitmap
{
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.display.Sprite;
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
			
			var info:FrameInfo, bounds:Rectangle;
			for (var index:int = 1; index <= totalFrames; index++)
			{
				target.gotoAndStop(index);
				
				// 获取有效像素边框
				bounds = target.getBounds(target.parent);
				
				// 防抖、像素对齐优化
				bounds.width = Math.ceil(bounds.width + bounds.x - (bounds.x >> 0));
				bounds.height = Math.ceil(bounds.height + bounds.y - (bounds.y >> 0));
				bounds.x >>= 0; bounds.y >>= 0;
				
				// 读取原生matrix, 适应任何变形对象
				matrix = target.transform.matrix;
				matrix.tx = -bounds.x + target.x;
				matrix.ty = -bounds.y + target.y;
				
				info = new FrameInfo(matrix.tx, matrix.ty, data);
				info.label = dict[index];
				info.index = index;
				
				data = new BitmapData(Math.max(bounds.width, 1), Math.max(bounds.height, 1), true, 0);
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