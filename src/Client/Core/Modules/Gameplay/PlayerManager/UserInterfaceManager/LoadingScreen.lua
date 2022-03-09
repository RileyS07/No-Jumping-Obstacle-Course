local contentProvider: ContentProvider = game:GetService("ContentProvider")
local replicatedFirst: ReplicatedFirst = game:GetService("ReplicatedFirst")
local textService: TextService = game:GetService("TextService")
local tweenService: TweenService = game:GetService("TweenService")

local coreModule = require(script:FindFirstAncestor("Core"))
local userInterfaceManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.UserInterfaceManager"))

local tweenInformation: TweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear)
local halfedTweenInformation: TweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Linear)

local thisInterface: GuiBase2d = userInterfaceManager.GetInterface(script.Name)
local loadingScreenFrameOne: Frame = thisInterface:WaitForChild("Frame1")
local loadingScreenFrameTwo: Frame = thisInterface:WaitForChild("Frame2")
local loadingScreenFrameThree: Frame = thisInterface:WaitForChild("Frame3")

local ThisInterfaceManager = {}

-- Initialize
function ThisInterfaceManager.Initialize()

    -- Showing this loading screen and removing the default one.
    -- We also want to load these assets into memory so it's clean.
    contentProvider:PreloadAsync(thisInterface:GetDescendants())
    userInterfaceManager.UpdateInterfaceShown(thisInterface)
    replicatedFirst:RemoveDefaultLoadingScreen()

    -- Playing the animations.
    -- We don't really check for loading status till frame three.
    task.spawn(function()
        ThisInterfaceManager._FrameOneStart()
        ThisInterfaceManager._FrameTwoStart()
        ThisInterfaceManager._FrameThreeStart()
    end)
end

-- Starts the animations for the first frame of the loading screen.
function ThisInterfaceManager._FrameOneStart()

    -- We need to define the assets we're going to use.
    -- We also need to define where the assets will end up.
    local title: TextLabel = loadingScreenFrameOne:WaitForChild("Title")
    local logo: ImageLabel = loadingScreenFrameOne:WaitForChild("Logo")
    local subheading: TextLabel = loadingScreenFrameOne:WaitForChild("Subheading")

    local titleFinalPosition: UDim2 = UDim2.fromScale(0.03, 0.45)
    local logoFinalPosition: UDim2 = UDim2.fromScale(1.25, 0.5)

    -- At first we just want to tween the title and logo into their final positions.
    local titleTween: Tween = tweenService:Create(
        title, tweenInformation, {Position = titleFinalPosition}
    )

    local logoTween: Tween = tweenService:Create(
        logo, tweenInformation, {Position = logoFinalPosition}
    )

    titleTween:Play()
    logoTween:Play()
    logoTween.Completed:Wait()

    -- Then we want to do an animation for the subheading.
    local subheadingTween: Tween = tweenService:Create(
        subheading,
        TweenInfo.new(0.1, Enum.EasingStyle.Linear),
        {MaxVisibleGraphemes = string.len(subheading.Text)}
    )

    subheadingTween:Play()
    subheadingTween.Completed:Wait()
    task.wait(0.5)
end

function ThisInterfaceManager._FrameTwoStart()

    -- We need to define the assets we're going to use.
    -- We also need to define where the assets will end up.
    local frameOneTitle: TextLabel = loadingScreenFrameOne:WaitForChild("Title")
    local frameOneLogo: ImageLabel = loadingScreenFrameOne:WaitForChild("Logo")
    local frameOneSubheading: TextLabel = loadingScreenFrameOne:WaitForChild("Subheading")
    local frameOneUIGradient: UIGradient = loadingScreenFrameOne:WaitForChild("UIGradient")
    local frameOnePattern: ImageLabel = loadingScreenFrameOne:WaitForChild("Pattern")

    local title: TextLabel = loadingScreenFrameTwo:WaitForChild("Title")
    local subheading: TextLabel = loadingScreenFrameTwo:WaitForChild("Subheading")
    local pattern: ImageLabel = loadingScreenFrameTwo:WaitForChild("Pattern")

    local titleOffset: Vector2 = textService:GetTextSize(
        frameOneTitle.Text, frameOneTitle.TextSize, frameOneTitle.Font.Value, frameOneTitle.AbsoluteSize
    )

    local subheadingOffset: Vector2 = textService:GetTextSize(
        frameOneSubheading.Text, frameOneSubheading.TextSize, frameOneSubheading.Font.Value, frameOneSubheading.AbsoluteSize
    )

    -- We want to move all of the frame one equivalents to their frame two values.
    frameOneTitle.Position -= UDim2.fromOffset(titleOffset.X, 0)
    frameOneSubheading.Position -= UDim2.fromOffset(subheadingOffset.X, 0)

    frameOneTitle.TextXAlignment = title.TextXAlignment
    frameOneSubheading.TextXAlignment = subheading.TextXAlignment

    tweenService:Create(
        frameOneTitle,
        tweenInformation,
        {
            AnchorPoint = title.AnchorPoint,
            Position = title.Position,
            TextColor3 = title.TextColor3
        }
    ):Play()

    tweenService:Create(
        frameOneLogo,
        tweenInformation,
        {Position = UDim2.fromScale(1.7, 0)}
    ):Play()

    tweenService:Create(
        frameOneSubheading,
        tweenInformation,
        {
            AnchorPoint = subheading.AnchorPoint,
            Position = subheading.Position,
            TextColor3 = title.TextColor3
        }
    ):Play()

    tweenService:Create(
        frameOnePattern,
        tweenInformation,
        {ImageColor3 = pattern.ImageColor3}
    ):Play()

    -- We need to work around this.
    tweenService:Create(
        frameOneUIGradient,
        halfedTweenInformation,
        {Offset = Vector2.new(-1, 0)}
    ):Play()

    task.wait(0.25)

    loadingScreenFrameOne.BackgroundColor3 = frameOneUIGradient.Color.Keypoints[2].Value
    frameOneUIGradient.Enabled = false

    tweenService:Create(
        loadingScreenFrameOne,
        halfedTweenInformation,
        {BackgroundColor3 = loadingScreenFrameTwo.BackgroundColor3}
    ):Play()

    task.wait(0.25)
    loadingScreenFrameTwo.Visible = true
    loadingScreenFrameOne.Visible = false
    task.wait(5)
end

function ThisInterfaceManager._FrameThreeStart()

    -- Make frame 2 black.
    local title: TextLabel = loadingScreenFrameTwo:WaitForChild("Title")
    local titleUIStroke: UIStroke = loadingScreenFrameTwo:WaitForChild("Title"):WaitForChild("UIStroke")
    local subheading: TextLabel = loadingScreenFrameTwo:WaitForChild("Subheading")
    local pattern: ImageLabel = loadingScreenFrameTwo:WaitForChild("Pattern")

    tweenService:Create(
        titleUIStroke, halfedTweenInformation, {Color = Color3.new()}
    ):Play()

    tweenService:Create(
        subheading, halfedTweenInformation, {TextColor3 = Color3.new()}
    ):Play()

    tweenService:Create(
        pattern, halfedTweenInformation, {ImageColor3 = Color3.new()}
    ):Play()

    task.wait(0.25)

    loadingScreenFrameThree.Visible = true
    titleUIStroke.Enabled = false

    tweenService:Create(
        title, halfedTweenInformation, {BackgroundTransparency = 1}
    ):Play()

    tweenService:Create(
        subheading, halfedTweenInformation,  {BackgroundTransparency = 1}
    ):Play()

    tweenService:Create(
        pattern, halfedTweenInformation,  {BackgroundTransparency = 1}
    ):Play()

    task.wait(0.25)

    loadingScreenFrameTwo.Visible = false

    task.wait(1)

    if userInterfaceManager.ActiveInterface == thisInterface then
        userInterfaceManager.UpdateInterfaceShown(thisInterface)
    end
end

return ThisInterfaceManager

--[[-- Variables
local specificInterfaceManager = {}
specificInterfaceManager.Interface = {}

local coreModule = require(script:FindFirstAncestor("Core"))
local userInterfaceManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.UserInterfaceManager"))
local clientEssentialsLibrary = require(coreModule.GetObject("Libraries.ClientEssentials"))
local clientAnimationsLibrary = require(coreModule.GetObject("Libraries.ClientAnimations"))

-- Initialize
function specificInterfaceManager.Initialize()
    specificInterfaceManager.Interface.ScreenGui = userInterfaceManager.GetInterface("LoadingScreen")
    specificInterfaceManager.Interface.Background = specificInterfaceManager.Interface.ScreenGui:WaitForChild("Background")
	specificInterfaceManager.Interface.BackgroundImages = specificInterfaceManager.Interface.Background:WaitForChild("BackgroundImages")
    specificInterfaceManager.Interface.Container = specificInterfaceManager.Interface.Background:WaitForChild("Container")
    specificInterfaceManager.Interface.Content = specificInterfaceManager.Interface.Container:WaitForChild("Content")
    specificInterfaceManager.Interface.Information = specificInterfaceManager.Interface.Content:WaitForChild("Information")
    specificInterfaceManager.Interface.Logo = specificInterfaceManager.Interface.Content:WaitForChild("LogoContainer")
    specificInterfaceManager.Interface.Skip = specificInterfaceManager.Interface.Content:WaitForChild("Right"):WaitForChild("Skip")

    userInterfaceManager.EnableInterface(specificInterfaceManager.Interface.ScreenGui.Name, {DisableOtherInterfaces = true, IsPriority = true})
    game:GetService("ReplicatedFirst"):RemoveDefaultLoadingScreen()
    clientEssentialsLibrary.SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

    clientAnimationsLibrary.PlayAnimation("LoadingScreenBackgroundImage", specificInterfaceManager.Interface.BackgroundImages)
    clientAnimationsLibrary.PlayAnimation("LoadingText...", specificInterfaceManager.Interface.Information:WaitForChild("Title"))

    -- We have to add this because some people have bad computers.
    task.delay(10, function()
        if userInterfaceManager.ActiveInterface ~= specificInterfaceManager.Interface.ScreenGui then return end
        coreModule.Shared.GetObject("//Remotes.GetUserData"):InvokeServer()

        -- They still gotta press skip.
        specificInterfaceManager.Interface.Skip.Visible = true
        local activatedConnection; activatedConnection = specificInterfaceManager.Interface.Skip.Activated:Connect(function()
            activatedConnection:Disconnect()
            specificInterfaceManager.Interface.Skip.Visible = false

            clientAnimationsLibrary.PlayAnimation(
                "LoadingScreenFinish",
                specificInterfaceManager.Interface.Information, specificInterfaceManager.Interface.BackgroundImages, specificInterfaceManager.Interface.Content
            )

            specificInterfaceManager.Interface = nil
        end)
    end)

    -- Let's load everything then go from there.
    coroutine.wrap(function()
        clientAnimationsLibrary.PlayAnimation("LoadingScreenLoadAssets", specificInterfaceManager.Interface.Information:WaitForChild("Description"))
        coreModule.Shared.GetObject("//Remotes.GetUserData"):InvokeServer()

        task.wait(5)

        if not specificInterfaceManager.Interface or not specificInterfaceManager.Interface.Skip.Visible then return end

        if userInterfaceManager.ActiveInterface == specificInterfaceManager.Interface.ScreenGui then
            clientAnimationsLibrary.PlayAnimation(
                "LoadingScreenFinish",
                specificInterfaceManager.Interface.Information, specificInterfaceManager.Interface.BackgroundImages, specificInterfaceManager.Interface.Content
            )

            specificInterfaceManager.Interface = nil
        end
    end)()
end


--
return specificInterfaceManager]]