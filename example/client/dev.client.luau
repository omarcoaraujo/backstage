--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Packages
const charm = require(ReplicatedStorage.roblox_packages.charm)
const vide = require(ReplicatedStorage.roblox_packages.vide)

--// Modules
const backstage = require(ReplicatedStorage.backstage)

--// End
backstage.start { vide = vide, charm = charm }
