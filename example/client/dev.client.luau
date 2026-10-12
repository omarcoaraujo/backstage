--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Packages
const vide = require(ReplicatedStorage.roblox_packages.vide)

--// Modules
const backstage = require(ReplicatedStorage.backstage)

--// End
backstage.start { vide = vide }
