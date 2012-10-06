package ifrog.utils
{
	import flash.utils.*;
	import flash.net.registerClassAlias;
	
	/**
	 * 深度复制一个有类型对象
	 * @important 如果被复制对象的构造函数需要传参，则复制失败！！
	 */
	public function cloneObject(data:Object):Object
	{
		if (!data) return null;
		
		registerClassAlias(getQualifiedClassName(data) + "::Alias", data.constructor);
		
		var bytes:ByteArray = new ByteArray();
		bytes.writeObject(data);
		
		bytes.position = 0;
		return bytes.readObject();
	}
}