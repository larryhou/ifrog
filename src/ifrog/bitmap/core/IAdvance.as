package ifrog.bitmap.core
{
	
	/**
	 * 依赖帧频渲染的类
	 * @author larryhou
	 * create a [IAdvance] interface
	 */
	public interface IAdvance
	{
		/**
		 * 渲染频率
		 */
		function get frameRate():uint;
		function set frameRate(value:uint):void;
		
		/**
		 * 执行帧渲染
		 * @param	step	滞后帧数
		 */
		function advance(step:uint):void;
	}
	
}