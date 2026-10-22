--// Modules
const guard = require "../../cli/guard"

--// Constants
const PORT = 34891

--// Specs
return {
	allows_the_client_of_studio = function()
		assert(guard.allows({ host = `127.0.0.1:{PORT}` }, PORT))
		assert(guard.allows({ host = `localhost:{PORT}` }, PORT))
	end,

	refuses_a_page_in_a_browser = function()
		assert(not guard.allows({ host = `127.0.0.1:{PORT}`, origin = "https://example.com" }, PORT))
		assert(not guard.allows({ host = `127.0.0.1:{PORT}`, origin = "null" }, PORT))
	end,

	refuses_a_host_that_is_not_loopback = function()
		assert(not guard.allows({ host = `evil.example:{PORT}` }, PORT))
		assert(not guard.allows({ host = "127.0.0.1:1" }, PORT))
		assert(not guard.allows({}, PORT))
	end,
}
