--// Constants
const LOOPBACK_HOSTS = { "127.0.0.1", "localhost", "[::1]" }

--// Functions
const function allows(headers: { [string]: string }, port: number)
	if headers.origin then return false end

	const host = headers.host
	if not host then return false end

	for _, name in LOOPBACK_HOSTS do
		if host == `{name}:{port}` then return true end
	end

	return false
end

--// End
return { allows = allows }
