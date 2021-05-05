-- Variables
local specificClientAnimation = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))
local userInterfaceManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.UserInterfaceManager"))
local gameplayMusicManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.GameplayMusic"))
local clientAnimationsLibrary = require(coreModule.GetObject("/Parent"))
local clientEssentialsLibrary = require(coreModule.GetObject("Libraries.ClientEssentials"))

-- Methods
function specificClientAnimation.Play(informationContainer, backgroundImage, contentContainer)
    if typeof(informationContainer) ~= "Instance" or not informationContainer:IsA("GuiObject") then return end
    if typeof(contentContainer) ~= "Instance" or not contentContainer:IsA("GuiObject") then return end
    if typeof(backgroundImage) ~= "Instance" or not backgroundImage:IsA("ImageLabel") then return end

    informationContainer:WaitForChild("Title").MaxVisibleGraphemes = informationContainer:WaitForChild("Title").Text:len()
    informationContainer:WaitForChild("Game").MaxVisibleGraphemes = informationContainer:WaitForChild("Game").Text:len()
    informationContainer:WaitForChild("Description").MaxVisibleGraphemes = informationContainer:WaitForChild("Description").Text:len()

    clientAnimationsLibrary.PlayAnimation("TweenMaxVisibleGraphemes", informationContainer:WaitForChild("Title"), 0)
    clientAnimationsLibrary.PlayAnimation("TweenMaxVisibleGraphemes", informationContainer:WaitForChild("Game"), 0)
    clientAnimationsLibrary.PlayAnimation("TweenMaxVisibleGraphemes", informationContainer:WaitForChild("Description"), 0):Wait()

    local downwardsTweenObject = coreModule.Services.TweenService:Create(contentContainer, TweenInfo.new(1, Enum.EasingStyle.Linear), {Position = UDim2.fromScale(0, 1.2)})
    downwardsTweenObject:Play()
    downwardsTweenObject.Completed:Wait()

    -- Fade to white now and also stop all the other animations.
    clientAnimationsLibrary.StopAnimation("LoadingScreenBackgroundImage")
    clientAnimationsLibrary.StopAnimation("LoadingText...")
    clientAnimationsLibrary.StopAnimation("LoadingScreenLoadAssets")

    coreModule.Services.TweenService:Create(backgroundImage:WaitForChild("Gradient"), TweenInfo.new(1, Enum.EasingStyle.Linear), {ImageTransparency = 1}):Play()

    local backgroundImageFadeTweenObject = coreModule.Services.TweenService:Create(backgroundImage, TweenInfo.new(1, Enum.EasingStyle.Linear), {ImageTransparency = 1})
    backgroundImageFadeTweenObject:Play()
    backgroundImageFadeTweenObject.Completed:Wait()

    local backgroundTransparencyFadeTweenObject = coreModule.Services.TweenService:Create(backgroundImage, TweenInfo.new(1, Enum.EasingStyle.Linear), {Transparency = 1})
    backgroundTransparencyFadeTweenObject:Play()
    backgroundTransparencyFadeTweenObject.Completed:Wait()

    userInterfaceManager.DisableInterface("LoadingScreen")
    gameplayMusicManager.UpdateMusic(coreModule.Shared.GetObject("//Remotes.Data.GetUserData"):InvokeServer())
    clientEssentialsLibrary.SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
end


--
return specificClientAnimation