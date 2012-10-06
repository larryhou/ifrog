package ifrog.utils
{
	import flash.xml.XMLNode;
	import flash.xml.XMLNodeType;
	
	/**
	 * @author Larry H.
	 * @createTime 2012/9/5 11:17
	 * 
	 * HTML特殊字符强力转义工具
	 * @param	content	包含特殊字符的字符串
	 * @param	violent	是否暴力转义，如果为true，则会将除下面这些字符的其他所有字符转义
	 * 0 1 2 3 4 5 6 7 8 9
	 * a b c d e f g h i j k l m n o p q r s t u v w x y z
	 * A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
	 * @ - _ . * + /
	 * 
	 * @return	被转义过的字符串
	 */
	public function escText(content:String, violent:Boolean = false):String 
	{
		if(!violent)
		{
			return new XMLNode(XMLNodeType.TEXT_NODE, content).toString();
		}
		
		return convert(content);
	}
}

// 暴力转换
function convert(content:String):String 
{
	content = escape(content);
	content = content.replace(/%([A-Z0-9]{2})/g, "&#x$1;");		// 转义半角字符
	content = content.replace(/%u([A-Z0-9]{4})/g, "&#x$1;");	// 转义全角字符
	return content;
}