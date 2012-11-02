package ifrog.utils
{
	/**
	 * 32位标记位
	 * @author larryhou
	 * @createTime 2012/8/24 14:17
	 */
	public class Byte4Flag
	{
		private var _bitmap:uint;
		
		/**
		 * 构造函数
		 * create a [Byte4Flag] object
		 */
		public function Byte4Flag(bitmap:uint = 0) 
		{
			_bitmap = bitmap;
		}
		
		/**
		 * 把指定位置的标志位设置为true
		 * @param	position	标记位置，从1开始
		 */
		public function set(position:uint/*1 <= position <= 32*/):void
		{			
			_bitmap |= 1 << (position - 1);
		}
		
		/**
		 * 把指定位置的标记为重置为false
		 * @param	position	标记位置，从1开始
		 */
		public function reset(position:uint/*1 <= position <= 32*/):void
		{
			_bitmap &= ~(1 << (position - 1));
		}
		
		/**
		 * 获取指定位置标志位
		 * @param	position	标记位置，从1开始
		 * @return	标记位是否为true
		 */
		public function get(position:uint/*1 <= position <= 32*/):Boolean
		{
			position--;
			return Boolean(_bitmap & 1 << position);
		}
		
		/**
		 * 把指定位置的标志位反转
		 * @param	position	标记位置，从1开始
		 */
		public function toggle(position:uint/*1 <= position <= 32*/):void
		{
			position--;
			_bitmap ^= 1 << position;
		}
		
		/**
		 * 标记位代表整形
		 */
		public function get bitmap():uint { return _bitmap; }
		public function set bitmap(value:uint):void 
		{
			_bitmap = value;
		}
	}

}