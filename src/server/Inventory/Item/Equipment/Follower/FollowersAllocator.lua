--// Packages
local Entity = require(game.ReplicatedStorage.Packages.Entity)

--// States
local AllocatedFollower = Entity.trait('AllocatedFollower', function(self, entity: Instance)
    
    self.index = -1
    function self:deallocate() self:unwrap() end
end)

--// Trait
return Entity.trait('FollowersAllocator', function(self, target)
    
    local allocateds = {}
    self.total = 0
    
    --// Methods
    function self:reallocateAll()
        
        local index = 0
        
        for entity, allocated in allocateds do
            
            index += 1
            allocated.index = index
        end
        self.total = index
    end
    function self:allocate(followerEntity: Instance)
        
        local allocated = AllocatedFollower.get(followerEntity)
        
        allocated:cleaner(function()
            
            allocateds[followerEntity] = nil
            self:reallocateAll()
        end)
        self:reallocateAll()
        
        allocateds[followerEntity] = allocated
        return allocated
    end
end)