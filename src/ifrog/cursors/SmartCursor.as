package ifrog.cursors
{
	import flash.display.*;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.sampler.DeleteObjectSample;
	import flash.ui.Mouse;
	import flash.utils.Dictionary;
	
	/**
	 * 智能鼠标指针
	 * 当用户FP不支持硬件指针时自动使用鼠标跟随
	 * 
	 * @author larryhou
	 * @createTime Sep 15, 2012 11:34:53 PM
	 */
	public class SmartCursor extends UserCursor
	{
		private static var _container:DisplayObjectContainer;
		
		private static var _hotSpot:Point;		
		private static var _cursor:Bitmap;
		
		private static var _map:Dictionary;
		private static var _supported:Boolean;
		
		/**
		 * 启动鼠标指针管理器
		 * @param container	模拟指针所在显示容器，一般为显示列表最顶层容器
		 * 
		 */		
		public static function startUp(container:DisplayObjectContainer):void
		{
			if(_container) return;
			
			_container = container;
			_container.addChild(_cursor = new Bitmap());
			
			_map = new Dictionary(false);
			_supported = ("registerCursor" in Mouse);
		}
		
		/**
		 * 校验初始化 
		 * 
		 */		
		private static function check():void
		{
			if(!_container)
			{
				throw new ArgumentError("SmartCursor.startUp方法未正确初始化");
			}
			else
			if(!_container.stage)
			{
				throw new ArgumentError("SmartCursor指针容器不在显示列表");
			}
		}
		
		/**
		 * 安装自定义鼠标指针
		 * @param	name		鼠标指针名称
		 * @param	source		鼠标指针素材源
		 * @param	frameRate	鼠标指针动画播放帧率
		 * @param	hotSpot		鼠标指针感应点所在位置，默认几何中心点
		 * 如果source为动画，则需要把frameRate设置成一个合理的帧率；其他情况，frameRate保持默认值1即可
		 */		
		public static function install(name:String, source:IBitmapDrawable, frameRate:uint = 1, hotspot:Point = null):void
		{
			check();
			
			_map[name] = UserCursor.install.apply(null, arguments);
		}
		
		/**
		 * 激活鼠标指针
		 * @param	name	鼠标指针名称
		 */
		public static function activate(name:String):void
		{
			check();
			
			var info:Object = _map[name];
			_hotSpot = info.hotSpot as Point;
			
			if(_supported)
			{
				Mouse.show();
				UserCursor.activate.apply(null, arguments);
				
				_cursor.parent && _container.removeChild(_cursor);
				_container.stage.removeEventListener(MouseEvent.MOUSE_MOVE, positionUpdate);
			}
			else
			{
				var data:Vector.<BitmapData> = info.data as Vector.<BitmapData>;
				if(data && data.length)
				{
					Mouse.hide();
					
					_cursor.bitmapData = data[0];
					if(!_hotSpot)
					{
						_hotSpot = new Point();
						_hotSpot.x = _cursor.width / 2;
						_hotSpot.y = _cursor.height / 2;
					}
					
					positionUpdate();
					_container.stage.addEventListener(MouseEvent.MOUSE_MOVE, positionUpdate);
				}
			}
				
		}
		
		/**
		 * 模拟指针鼠标跟随逻辑 
		 * 
		 */		
		private static function positionUpdate(e:MouseEvent = null):void
		{
			_cursor.x = _container.stage.mouseX - _hotSpot.x;
			_cursor.y = _container.stage.mouseY - _hotSpot.y;
		}
		
		/**
		 * 卸载已注册的鼠标指针
		 * @param	name	鼠标指针名称
		 */
		public static function uninstall(name:String):void
		{
			check();
			
			delete _map[name];
			UserCursor.uninstall.apply(null, arguments);
		}
	}
}