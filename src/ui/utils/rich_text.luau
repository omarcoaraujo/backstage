--// Functions
const function escape(text: string)
	const ampersands = string.gsub(text, "&", "&amp;")
	const opened = string.gsub(ampersands, "<", "&lt;")
	return (string.gsub(opened, ">", "&gt;"))
end

--// End
return function(text: string, emphasis: string?)
	const replacement = if emphasis then `<font color="{emphasis}"><b>%1</b></font>` else "<b>%1</b>"
	return (string.gsub(escape(text), '"([^"]+)"', replacement))
end
