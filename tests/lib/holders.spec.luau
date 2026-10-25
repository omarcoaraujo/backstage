--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const holders = require(ReplicatedStorage.backstage.core.holders)

--// Specs
return {
	first_to_claim_holds = function()
		holders.reset()
		assert(holders.claim(1, "pets.speed"))
		
		assert(not holders.claim(2, "pets.speed"))
		assert(holders.holder "pets.speed" == 1)
	end,

	same_user_can_claim_again = function()
		holders.reset()
		assert(holders.claim(1, "pets.speed"))
		assert(holders.claim(1, "pets.speed"))
	end,

	moving_to_another_value_frees_the_first = function()
		holders.reset()

		holders.claim(1, "pets.speed")
		holders.claim(1, "pets.size")

		assert(holders.holder "pets.speed" == nil)
		assert(holders.claim(2, "pets.speed"))
	end,

	claiming_nothing_frees_the_user = function()
		holders.reset()
		holders.claim(1, "pets.speed")
		
		assert(holders.claim(1, nil))
		assert(holders.holder "pets.speed" == nil)
	end,

	a_refused_claim_frees_what_the_user_held_before = function()
		holders.reset()
		holders.claim(1, "pets.speed")
		holders.claim(2, "pets.size")
		
		assert(not holders.claim(2, "pets.speed"))
		assert(holders.holder "pets.size" == nil)
	end,

	release_frees_the_user = function()
		holders.reset()
		holders.claim(1, "pets.speed")
		
		holders.release(1)
		assert(holders.holder "pets.speed" == nil)
	end,
}
