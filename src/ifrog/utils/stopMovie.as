package ifrog.utils
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	/**
	 * 递归停止影片剪辑
	 * @author larryhou
	 * @createTime 2012/10/30 17:44
	 */
	public function stopMovie(container:DisplayObjectContainer):void
	{
		var child:DisplayObject;
		for (var i:int = 0; i < container.numChildren; i++)
		{
			child = container.getChildAt(0);
			if (child is DisplayObjectContainer)
			{
				if (child is MovieClip)	MovieClip(child).stop();
				arguments.callee.call(null, child as DisplayObjectContainer);
			}
		}
	}
}