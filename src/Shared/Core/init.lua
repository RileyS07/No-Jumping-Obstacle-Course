local CoreModule = {}

-- Initialize
function CoreModule.Initialize()
	print("[Core]: Loading " .. script.Parent.Name .. ".")

    -- Loading and Initializing the modules and important libraries.
	CoreModule.LoadModule("Modules/")
    CoreModule.LoadModule("Libraries.Services/")

	print("[Core]: Done loading " .. script.Parent.Name .. ".")
end

-- Fetches the object at the desired path, can specify where to start looking with prefixes.
function CoreModule.GetObject(objectPath: string, environmentOffset: number?, showDebugMessage: boolean?) : Instance

	-- Initial values for the search.
	local searchLocation: Instance = script
	local searchPathArray: {string}? = string.split(objectPath, ".")

	-- //Path... starts looking from the machine source folder.
	-- /Path... starts looking from the local source script.
	if string.match(objectPath, "^//") then
		searchLocation = script.Parent

		if string.match(objectPath, "^//(.+)") then
			searchPathArray = string.split(string.match(objectPath, "^//(.+)") :: string, ".")
		else
			searchPathArray = nil
		end
	elseif string.match(objectPath, "^/") then
		searchLocation = getfenv(2 + (environmentOffset or 0)).script

		if string.match(objectPath, "^/(.+)") then
			searchPathArray = string.split(string.match(objectPath, "^/(.+)") :: string, ".")
		else
			searchPathArray = nil
		end
	end

	-- Now we follow the searchPathArray and hopefully find the object.
	if searchPathArray then
		for _, childName in next, searchPathArray do
			searchLocation = searchLocation:WaitForChild((string.gsub(childName, "/$", "")))
		end
	end

	-- Do we debug?
	if showDebugMessage then
		print("[Core]: Fetched " .. searchLocation:GetFullName() .. ".")
	end

	return searchLocation
end

-- Loads a module supported by the system. !Must have an Initialize method!
function CoreModule.LoadModule(objectPath: string, ...: any)

    -- First we have to get the module script in question.
	local moduleScript: Instance = CoreModule.GetObject(objectPath, 1)

    -- When using the character '/' the loader attempts to load all children modules.
	if string.sub(objectPath, -1, -1) == "/" then
		for _, child in next, moduleScript:GetChildren() do
			if child:IsA("ModuleScript") then
				print("[Core]: Loading " .. child:GetFullName() .. ".")

                -- We want to see IF we can initialize it.
                local returnedTable: {} = require(child)

                if returnedTable.Initialize then
                    returnedTable.Initialize(...)
                    print("[Core]: Initialized " .. child:GetFullName() .. ".")
                else
                    print("[Core]: Loaded " .. child:GetFullName() .. ".")
                end
			end
		end
	else
		print("[Core]: Loading " .. moduleScript:GetFullName() .. ".")

        -- We want to see IF we can initialize it.
        local returnedTable: {} = require(moduleScript)

        if returnedTable.Initialize then
            returnedTable.Initialize(...)
            print("[Core]: Initialized " .. moduleScript:GetFullName() .. ".")
        else
            print("[Core]: Loaded " .. moduleScript:GetFullName() .. ".")
        end
	end
end

return CoreModule
