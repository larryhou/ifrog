package ifrog.math
{
	/**
	 * @author Larry.H
	 * 
	 * 排列组合函数
	 * @param	src		排列源
	 * @param	level	排列阶数
	 * @param	random	是否随机一个排列返回
	 * @return	返回所有可能排列结果
	 */
	public function permutate(src:Array, level:uint = 0, random:Boolean = false):Array
	{
		if (!src || !src.length) return [];
		
		src = src.concat();
		level = Math.min(src.length, level);
		
		return random? r_kernal(src, level) : kernal(src, level);
	}
}

/**
 * 递归函数
 */
function r_kernal(list:Array, level:uint):Array
{
	var result:Array = [];
	
	var index:int;
	
	var depth:int = 0;
	while (depth < level)
	{
		depth++;
		
		index = Math.random() * list.length >> 0;
		result = result.concat(list.splice(index, 1));
	}
	
	return result;
}


/**
 * 递归函数
 */
function kernal(list:Array, level:uint, output:Array = null, possible:Array = null, depth:uint = 0):Array
{
	output ||= [];
	if (depth == level)
	{
		output.push(possible);
	}
	else
	{
		possible ||= [];
		var length:int = list.length;
		for (var i:int = 0; i < length; i++)
		{
			var _possible:Array = possible.concat();
			_possible.push(list[i]);
			
			var _list:Array = list.concat();
			_list.splice(i, 1);
			
			arguments.callee(_list, level, output, _possible, depth + 1);
		}
	}
	
	return output;
}