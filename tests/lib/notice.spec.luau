--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const notice = require(ReplicatedStorage.backstage.core.notice)

--// Specs
return {
	show_tells_the_listeners_with_the_text_and_the_kind = function()
		notice.reset()
		const heard = {} :: { string }

		notice.on_notice(function(text, kind)
			table.insert(heard, `{kind}:{text}`)
		end)

		notice.show("Not saved", "error")

		assert(#heard == 1 and heard[1] == "error:Not saved")
		notice.reset()
	end,

	show_shares_the_notice_with_the_other_players = function()
		notice.reset()
		const shared = {} :: { string }

		notice.connect_remote(function(text, kind, detail)
			table.insert(shared, `{kind}:{text}:{detail}`)
		end)

		notice.show("Not saved", "error", "no room")

		assert(#shared == 1 and shared[1] == "error:Not saved:no room")
		notice.reset()
	end,

	receive_ignores_a_detail_that_is_not_text = function()
		notice.reset()
		local heard = "unset" :: string?

		notice.on_notice(function(_, _, detail)
			heard = detail
		end)

		notice.receive("Hello", "info", 42)

		assert(heard == nil)
		notice.reset()
	end,

	receive_does_not_share_the_notice_again = function()
		notice.reset()
		local shared = 0
		local heard = 0

		notice.connect_remote(function()
			shared += 1
		end)

		notice.on_notice(function()
			heard += 1
		end)

		notice.receive("Not saved", "error")

		assert(heard == 1)
		assert(shared == 0)
		notice.reset()
	end,

	receive_keeps_the_success_kind = function()
		notice.reset()
		local heard = nil :: string?

		notice.on_notice(function(_, kind)
			heard = kind
		end)

		notice.receive("Connected", "success")

		assert(heard == "success")
		notice.reset()
	end,

	receive_turns_an_unknown_kind_into_info = function()
		notice.reset()
		local heard = nil :: string?

		notice.on_notice(function(_, kind)
			heard = kind
		end)

		notice.receive("Hello", 42)

		assert(heard == "info")
		notice.reset()
	end,

	the_stop_function_removes_the_listener = function()
		notice.reset()
		local heard = 0

		const stop = notice.on_notice(function()
			heard += 1
		end)

		stop()
		notice.show("Not saved", "error")

		assert(heard == 0)
		notice.reset()
	end,
}
