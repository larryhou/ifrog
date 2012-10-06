package ifrog.bitmap.core
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	
	/**
	 * 位图帧
	 * @author Larry H.
	 * @createTime 2012/5/23 11:28
	 */
	public class FrameInfo 
	{
		// 帧序号
		public var index:int;
		
		// 帧标签
		public var label:String;
		
		// 整形坐标
		public var x:Number;
		
		// 整形坐标
		public var y:Number;
		
		// 帧数据
		public var data:BitmapData;
		
		// 与第一帧的偏移
		public var offset:Point;
		
		/**
		 * 构造函数
		 * create a [FrameInfo] object
		 */
		public function FrameInfo(x:Number = 0, y:Number = 0, data:BitmapData = null) 
		{
			this.x = x; this.y = y; this.data = data;
		}
	}

}