--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Packages
const charm = require(ReplicatedStorage.roblox_packages.charm)
const vide = require(ReplicatedStorage.roblox_packages.vide)

--// Modules
const backstage = require(ReplicatedStorage.backstage)
const pets = require(ReplicatedStorage.client_modules.pets)

--// Components
const app = require(ReplicatedStorage.ui.app)

--// End
backstage.start { vide = vide, charm = charm }
app.mount()
pets.spawn()
