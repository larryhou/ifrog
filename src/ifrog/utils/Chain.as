package ifrog.utils
{
	import flash.utils.Dictionary;
	import flash.utils.describeType;
	
	/**
	 * 把数组转换成数据链
	 * @author larryhou
	 * @createTime 2012/10/23 15:42
	 */
	public class Chain 
	{
		private var _current:Node;
		private var _nodes:Vector.<Node>;
		
		private var _map:Dictionary;
		
		/**
		 * 构造函数
		 * create a [Chain] object
		 * @param	list		链条数据源：数组
		 * @param	enclosed	是否收尾相连
		 */
		public function Chain(list:*/*[Array *] or [Vector *]*/, enclosed:Boolean = false)
		{
			_map = new Dictionary();
			_nodes = new Vector.<Node>;
			
			var name:String = describeType(list).@name;
			if (name.match(/^__AS3__\.vec::Vector/) || name == "Array")
			{				
				var length:int = list.length;
				for (var i:int = 0; i < length; i++)
				{
					_nodes.push(_map[list[i]] = new Node(list[i]));
				}
				
				// 行程铰链
				for (i = 0; i < length; i++)
				{
					if (i > 0) _nodes[i].last = _nodes[i - 1];
					if (i < length - 1) _nodes[i].next = _nodes[i + 1];
				}
				
				if (_nodes.length)
				{
					_current = _nodes[0];
					
					if (enclosed)
					{
						// 首尾相连
						_nodes[length - 1].next = _nodes[0];
						_nodes[0].last = _nodes[length - 1];
					}
				}
			}
			
			_nodes.fixed = true;
		}
		
		/**
		 * 向前进
		 * @return	节点数据
		 */
		public function forword():*
		{
			if (_current.next) _current = _current.next;
			
			return this.current;
		}
		
		/**
		 * 向后退
		 * @return	节点数据
		 */
		public function backword():*
		{
			if (_current.last) _current = _current.last;
			
			return this.current;
		}
		
		/**
		 * 销毁耦合链条，垃圾回收
		 */
		public function dispose():void
		{
			_map = null;
			
			_nodes.fixed = false;
			for each(var item:Node in _nodes)
			{
				item.last = null;
				item.next = null;
				item.data = null;
			}
			
			_nodes = null;
			_current = null;
		}
		
		// getter & setter
		//*************************************************
		/**
		 * 当前节点数据
		 */
		public function get current():* { return _current? _current.data : null; }
		public function set current(value:*):void
		{
			if (_map[value]) _current = _map[value] as Node;
		}
		
		/**
		 * 下一个节点数据
		 */
		public function get next():* { return (_current && _current.next)? _current.next.data : null; }
		
		/**
		 * 上一个节点数据
		 */
		public function get last():* { return (_current && _current.last)? _current.last.data : null; }
	}
}

class Node 
	{
		/**
		 * 上一个节点
		 */
		public var last:Node;
		
		/**
		 * 下一个节点
		 */
		public var next:Node;
		
		/**
		 * 节点数据
		 */
		public var data:*;
		
		
		/**
		 * 构造函数
		 * create a [Node] object
		 * @param	data	节点数据
		 */
		public function Node(data:* = null)
		{
			this.data = data;
		}
	}