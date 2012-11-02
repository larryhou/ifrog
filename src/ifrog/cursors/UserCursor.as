package ifrog.cursors
{
	import flash.display.*;
	import flash.geom.*;
	import flash.system.ApplicationDomain;
	import flash.ui.*;
	import flash.utils.Dictionary;
	
	/**
	 * 系统鼠标指针
	 * @author larryhou
	 * @createTime 2012/9/11 10:33
	 * @important  兼容10.0以上所有版本
	 * 工具支持任意IBitmapDrawable(MovieClip、Sprite、Shape、Bitmap、BitmapData等)对象制作系统鼠标指针
	 * 
	 * 系统鼠标指针限定宽高不超过32像素，工具会自动做处理：
	 * 1、如果IBitmapDrawable对象宽、高不超过32像素，则原样展示
	 * 2、如果IBitmapDrawable对象宽、高至少一个超过32像素，则工具将会等比缩放宽、高，保证刚好满足限制条件
	 */
	public class UserCursor 
	{
		// 鼠标指针类型定义
		//*************************************************
		/**
		 * 默认鼠标指针
		 */
		public static const NORMAL:String = "UserCursor::NORMAL";
		
		// 静态工具方法
		//*************************************************
		private static const _domain:ApplicationDomain = ApplicationDomain.currentDomain;
		private static const _map:Dictionary = new Dictionary(false);
		
		/**
		 * 安装自定义鼠标指针
		 * @param	name		鼠标指针名称
		 * @param	source		鼠标指针素材源
		 * @param	frameRate	鼠标指针动画播放帧率
		 * @param	hotSpot		鼠标指针感应点所在位置，默认几何中心点
		 * 如果source为动画，则需要把frameRate设置成一个合理的帧率；其他情况，frameRate保持默认值1即可
		 */
		public static function install(name:String, source:IBitmapDrawable, frameRate:uint = 1, hotSpot:Point = null):Object
		{
			if (!source) return null;
			
			var container:Sprite = new Sprite();
		 	
			var frame:BitmapData;
			var rect:Rectangle, matrix:Matrix;
			var data:Vector.<BitmapData> = new Vector.<BitmapData>;
			
			var scale:Number = 1;
			
			// 鼠标指针最大32×32像素
			const MAX_LEN:uint = 32;
			if (source is BitmapData)
			{
				var info:BitmapData = source as BitmapData;
				
				rect = info.rect;
				if (rect.width > MAX_LEN || rect.height > MAX_LEN)
				{
					if (rect.width > rect.height)
					{
						scale = MAX_LEN / rect.width;
					}
					else
					{
						scale = MAX_LEN / rect.height;
					}
				}
				
				matrix = new Matrix();
				frame = new BitmapData(Math.max(1, rect.width * scale), Math.max(1, rect.height * scale), true, 0x00FF0000);
				
				matrix.scale(scale, scale);
				frame.draw(source, matrix, null, null, null, true);
				
				data.push(frame);
			}
			else
			if (source is DisplayObject)
			{
				container.addChild(source as DisplayObject);
				
				var movie:MovieClip;
				var target:DisplayObject = source as DisplayObject;
				target.scaleX = target.scaleY = 1;
				
				var index:int;
				if(source is MovieClip)
				{
					movie = source as MovieClip;
					
					index = 1;
					rect = new Rectangle();
					while (index <= movie.totalFrames)
					{
						movie.gotoAndStop(index++);
						rect = rect.union(movie.getBounds(movie.parent));
					}
				}
				else
				{
					rect = target.getBounds(target.parent);
				}
				
				if (rect.width > MAX_LEN || rect.height > MAX_LEN)
				{
					if (rect.width > rect.height)
					{
						scale = MAX_LEN / rect.width;
					}
					else
					{
						scale = MAX_LEN / rect.height;
					}
				}
				
				if (movie)
				{
					index = 1;
					while (index <= movie.totalFrames)
					{
						movie.gotoAndStop(index++);
						data.push(createInfo(movie, rect, scale));
					}
				}
				else
				{
					data.push(createInfo(target, rect, scale));
				}
				
				target.parent && target.parent.removeChild(target);
			}
			
			frame = data[0];
			
			if (!hotSpot)
			{
				hotSpot = new Point();
				hotSpot.x = rect.width * scale >> 1;
				hotSpot.y = rect.height * scale >> 1;
			}
			else
			{
				hotSpot.x = Math.max(0, Math.min(frame.width, hotSpot.x));
				hotSpot.y = Math.max(0, Math.min(frame.height, hotSpot.y));
			}
			
			var cursor:*;
			var definition:String = "flash.ui.MouseCursorData";
			if(_domain.hasDefinition(definition))
			{
				cursor = new (_domain.getDefinition(definition) as Class)();
				cursor.frameRate = frameRate;
				cursor.hotSpot = hotSpot;
				cursor.data = data;
			
				uninstall(name);
				(Mouse["registerCursor"] as Function).apply(null, [name, cursor]);
				
				_map[name] = cursor;
			}
			else
			{
				_map[name] = { data:data, hotSpot:hotSpot, frameRate:frameRate };
			}
			
			return _map[name];
		}
		
		/**
		 * 卸载已注册的鼠标指针
		 * @param	name	鼠标指针名称
		 */
		public static function uninstall(name:String):void
		{
			if ("unregisterCursor" in Mouse)
			{
				(Mouse["unregisterCursor"] as Function).apply(null, [name]);
			}
			
			var cursor:* = _map[name];
			if (cursor)
			{
				var data:Vector.<BitmapData> = cursor.data;
				while (data.length)
				{
					data.shift().dispose();
				}
			}
			
			delete _map[name];
		}
		
		/**
		 * 制作动画单帧
		 */
		protected static function createInfo(source:DisplayObject, rect:Rectangle, scale:Number):BitmapData
		{
			var data:BitmapData, matrix:Matrix;
			data = new BitmapData(Math.max(1, rect.width * scale), Math.max(1, rect.height * scale), true, 0x00FF0000);
			
			matrix = new Matrix();
			matrix.translate(source.x - rect.x, source.y - rect.y);
			matrix.scale(scale, scale);
			
			data.draw(source, matrix, null, null, null, true);
			return data;
		}
		
		/**
		 * 激活鼠标指针
		 * @param	name	鼠标指针名称
		 */
		public static function activate(name:String):void
		{
			// 相同鼠标指针不需要重复设置
			if (name == Mouse.cursor) return;
			
			var exception:Boolean = false;
			
			try
			{
				Mouse.cursor = name;
			}
			catch (err:Error)
			{
				exception = true;
				trace("[UserCursor]鼠标指针指针\"" + name + "\"不存在\n" + err);
			}
			
			var linkage:String = "flash.ui.MouseCursor";
			if (exception && _domain.getDefinition(linkage))
			{
				Mouse.cursor = _domain.getDefinition(linkage).AUTO;
			}
		}
		
		/**
		 * 把当前鼠标指针重置为默认鼠标指针
		 * @notice	如果默认鼠标指针不存在，则使用系统鼠标指针
		 */
		public static function restore():void
		{
			activate(NORMAL);
		}
	}
}