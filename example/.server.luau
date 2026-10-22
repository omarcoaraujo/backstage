--// Services
const ReplicatedStorage = game:GetService "ReplicatedStorage"

--// Modules
const backstage = require(ReplicatedStorage.backstage)

--// End
require(ReplicatedStorage.data)
backstage.start()
