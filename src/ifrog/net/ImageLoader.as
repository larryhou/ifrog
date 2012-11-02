package ifrog.net
{
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.utils.Dictionary;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;

	/**
	 * 加载完成
	 */
	[Event(name = "complete", type = "flash.events.Event")]
	
	/**
	 * 图片加载器
	 * @author Larry H.
	 */
	public class ImageLoader extends EventDispatcher
	{
		// 图片加载缓存管理逻辑
		//*************************************************
		private static const _manager:Dictionary = new Dictionary(false);
		
		/**
		 * 分配缓存空间
		 * @param name	缓存名称
		 */		
		public static function cacheAlloc(name:String):void
		{
			_manager[name] = new Dictionary(false);
		}
		
		/**
		 * 删除缓存，释放内存
		 * @param name	缓存名称
		 */		
		public static function dispose(name:String):void
		{
			var cache:Dictionary = _manager[name];
			for each (var item:* in cache) unload(item as Loader);

			delete _manager[name];
		}
		
		/**
		 * 下载加载器资源
		 * @param loader	加载器实例
		 */		
		private static function unload(loader:Loader):void
		{
			if (!loader) return;
			
			var info:LoaderInfo = loader.contentLoaderInfo;
			if (info.bytesLoaded < info.bytesTotal)
			{
				loader.close();
			}
			else
			{
				try
				{
					loader.unloadAndStop(true);
				} 
				catch(error:Error) 
				{
					loader.unload();
				}
			}
		}
		
		// 实体类逻辑
		//*************************************************
		private var _container:DisplayObjectContainer;
		
		private var _url:String;
		private var _loader:Loader;
		private var _loading:Boolean;
		
		private var _width:Number;
		private var _height:Number;
		
		private var _border:Number;
		private var _defaultImage:String;
		
		private var _id:uint;
		
		private var _cache:Dictionary;
		private var _cacheName:String;
		
		private var _retried:Boolean;
		
		private var _usingMask:Boolean;
		
		private var _indicator:MovieClip;
		
		/**
		 * 构造函数
		 * create a [ImageLoader] object
		 * @param	container	图片加载容器
		 * @param	hasMask		container中是否包含遮罩层，如果有则需放到container的最底层
		 * @param	width		图片宽度，如果大于0则使用该宽度作为图片的最终宽度，否则使用container宽度
		 * @param	height		图片高度，如果大于0则使用该高度作为图片的最终高度，否则使用container高度
		 * @notice	
		 */
		public function ImageLoader(container:DisplayObjectContainer, hasMask:Boolean = false, width:Number = NaN, height:Number = NaN)
		{
			_container = container;
			
			_width = isNaN(width)? _container.width : Math.max(0, width);
			_height = isNaN(height)? _container.height : Math.max(0 , height);
			
			_width /= _container.scaleX;
			_height /= _container.scaleY;
			
			this.border = 0;
			
			_usingMask = hasMask;
			if (_usingMask) _container.mask = _container.getChildAt(0);
		}
		
		/**
		 * 加载
		 * @param	url			图片地址
		 * @param	delayTime	延迟加载时间：毫秒数
		 */
		public function load(url:String, delayTime:uint = 0):void
		{
			_url = url;
			_retried = false;
			
			if (delayTime == 0)
			{
				execute(); return;
			}
			
			_id = setTimeout(execute, delayTime);
		}
		
		/**
		 * 执行加载
		 */
		private function execute(url:String = null):void
		{	
			_loading = true;
			
			if (url) _url = url;			
			if(_cache && _cache[_url])
			{
				_loader = _cache[_url];	completeHandler(null);
			}
			else
			if(!_url)
			{
				errorHandler(null);
			}
			else
			{
				_loader = new Loader();
				_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, completeHandler);
				_loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
				_loader.load(new URLRequest(_url));
				
				if (_indicator)
				{
					_indicator.x = _width / 2;
					_indicator.y = _height / 2;
					
					_indicator.play();
					_container.addChild(_indicator);
				}
			}
		}
		
		/**
		 * 加载失败处理
		 * @param	e
		 */
		private function errorHandler(e:IOErrorEvent):void 
		{			
			if (_indicator)
			{
				_indicator.stop();
				_indicator.parent && _indicator.parent.removeChild(_indicator);
			}
			
			if (!_defaultImage || _retried) return;
			_retried = true;
			
			trace(this + "加载失败！现在加载默认图片。。");
			
			var reg:RegExp = /\.(jpg|jpeg|png|gif|bmp)$/i;
			if (reg.test(_defaultImage.split("?")[0]))
			{
				execute(_defaultImage); return;
			}
			
			var image:DisplayObject;
			var domain:ApplicationDomain = ApplicationDomain.currentDomain;
			
			if (domain.hasDefinition(_defaultImage))
			{
				image = new (domain.getDefinition(_defaultImage) as Class)() as DisplayObject;
				if (image is DisplayObjectContainer)
				{
					(image as DisplayObjectContainer).mouseEnabled = false;
					(image as DisplayObjectContainer).mouseChildren = false;
				}
				
				image && processImage(image);
			}
			else
			{
				trace(this + "默认图片不可用：defaultImage = " + _defaultImage);
			}
			
			dispatchEvent(new Event(Event.COMPLETE)); 
		}
		
		/**
		 * 加载完成
		 * @param	e
		 */
		private function completeHandler(e:Event):void 
		{
			if (_indicator)
			{
				_indicator.stop();
				_indicator.parent && _indicator.parent.removeChild(_indicator);
			}
			
			_loading = false;
			if (!_loader)
			{
				clear(); return;
			}
			
			processImage(_loader);
			
			// 加入缓存
			if (_cache && !_cache[_url]) _cache[_url] = _loader;
			
			// 派发加载完成事件
			dispatchEvent(new Event(Event.COMPLETE));
		}
		
		/**
		 * 处理加载完成的图片
		 */
		private function processImage(image:DisplayObject):void
		{
			image.x = image.y = 0;
			image.scaleX = image.scaleY = 1;
			
			var scaleX:Number = (_width - _border * 2 + 1) / image.width;
			var scaleY:Number = (_height - _border * 2 + 1) / image.height;
			
			var scale:Number;
			if (!_width || !_height)
			{
				if (!_width) scale = scaleY;
				if (!_height) scale = scaleX;
				if (!_width && !_height) scale = 1;
			}
			else
			{
				scale = (scaleX * image.height > _height - _border * 2 + 1)? scaleY : scaleX;
			}
			
			image.scaleX = image.scaleY = scale;
			
			_container.addChild(image);
			
			// 居中对齐
			var bounds:Rectangle = image.getBounds(_container);
			if (_width > 0) image.x = (_width - bounds.width) / 2 - bounds.x;
			if (_height > 0) image.y = (_height - bounds.height) / 2 - bounds.y;
			
			// 平滑显示图片
			ImageLoader.smoothImage(image);
		}
		
		/**
		 * 平滑图片
		 * @param	target
		 */
		public static function smoothImage(target:DisplayObject):void
		{
			if(target is Loader)
			{
				try
				{
					target = (target as Loader).content;
				}
				catch(error:Error)
				{
					return;	// 安全沙箱错误
				}
			}
			
			if (target is Bitmap)
			{
				(target as Bitmap).smoothing = true; return;
			}
			
			var container:Sprite = target as Sprite;
			if (container)
			{
				var child:DisplayObject;
				for (var i:int = 0; i < container.numChildren; i++)
				{
					child = container.getChildAt(i);
					if (child is Bitmap) (child as Bitmap).smoothing = true;
					if (child is DisplayObjectContainer) arguments.callee(child);
				}
			}
		}
		
		/**
		 * 清除
		 */
		public function clear():void
		{			
			clearTimeout(_id);
			
			if (_loader && !_cache) unload(_loader);
			_loader = null; _url = null;
			
			var keep:int = int(_usingMask);
			while (_container.numChildren > keep) _container.removeChildAt(_container.numChildren - 1);
		}
		
		/**
		 * 销毁
		 */
		public function dispose():void
		{
			clear();
			
			_container.mask = null;
		}
		
		// getter & setter
		//*************************************************
		/**
		 * 加载loader
		 */
		public function get content():Loader  { return _loader; }
		
		/**
		 * 默认头像
		 * @notice	可以是链接名或者图片url
		 */
		public function get defaultImage():String { return _defaultImage; }
		public function set defaultImage(value:String):void 
		{
			_defaultImage = value; 
		}
		
		/**
		 * 边框像素数
		 * @default 1
		 */
		public function get border():Number { return _border; }
		public function set border(value:Number):void 
		{
			_border = isNaN(value)? 0 : value;
		}
		
		/**
		 * 是否正在加载
		 */
		public function get loading():Boolean { return _loading; }
		
		/**
		 * 图片地址
		 */
		public function get url():String { return _url; }
		public function set url(value:String):void 
		{
			_url = value;
		}
		
		/**
		 * 素材加载指示动画
		 * @important	动画(0, 0)坐标在几何中心
		 */
		public function get indicator():MovieClip { return _indicator; }
		public function set indicator(value:MovieClip):void 
		{
			_indicator = value;
			_indicator && _indicator.stop();
		}

		/**
		 * 图片缓存名称 
		 */		
		public function get cacheName():String { return _cacheName;	}
		public function set cacheName(value:String):void
		{
			_cacheName = value;
			_cache = _manager[_cacheName];
		}

	}

}