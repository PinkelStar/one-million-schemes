#
#  AppDelegate.rb
#  One Million Schemes
#
#  Created by Josh Kalderimis on 4/19/11.
#  Copyright 2011 Zwapp. All rights reserved.
#

class AppDelegate
  attr_accessor :window, :twitterPromptWindow
  attr_accessor :mainText, :secondaryText
  attr_accessor :progressIndicator, :startButton, :statusLabel
  attr_accessor :twitterName, :errorLabel
  attr_accessor :notificationCenter
  
  def applicationDidFinishLaunching(notification)
    setupNotificationsObservers
  end
  
  def setupNotificationsObservers
    @notificationCenter = NSNotificationCenter.defaultCenter
    
    ["appsFound", 
     "processingFinished", 
     "uploadingStarted", 
     "uploadingFinished"].each do |name|
      addNotificationObserver(name)
    end
  end
  
  def addNotificationObserver(name)
    titleized = name[0].capitalize + name[1..-1]
    @notificationCenter.addObserver(self, selector: "#{name}:", name: titleized, object: nil)
  end
  
  def startUpload(sender)
    increaseFrameSize
    
    toggleUIState
    
    IpaProcessor.updateApps do |appList|
      @recentAppList = appList
      promptForTwitterName
    end
  end
  
  def promptForTwitterName
    NSApp.beginSheet(twitterPromptWindow, 
                     modalForWindow: window,
                     modalDelegate: self,
                     didEndSelector: "didEndSheet:returnCode:contextInfo:",
                     contextInfo: nil)
  end
  
  def uploadWithoutTwitterName(sender)
    NSApp.endSheet(twitterPromptWindow)
    uploadAppList(nil)
  end
  
  def uploadWithTwitterName(sender)
    NSApp.endSheet(twitterPromptWindow)
    twitterName = self.twitterName.stringValue
    TwitterNameChecker.start(twitterName) do |valid|
      if valid
        uploadAppList(twitterName)
      else
        self.errorLabel.stringValue = "can't seem to find it"
        promptForTwitterName
      end
    end
  end
  
  def didEndSheet(sheet, returnCode: returnCode, contextInfo: contextInfo)
    sheet.orderOut(self)
  end
  
  def uploadAppList(twitterName)
    PlistUploader.start(@recentAppList, twitterName) do
      @notificationCenter.postNotificationName("UploadingFinished", object: self)
      toggleUIState
      reduceFrameSize
    end
  end

  def increaseFrameSize
    changeFrameHeight(75)
  end
  
  def reduceFrameSize
    changeFrameHeight(-75)
  end
  
  def changeFrameHeight(heightDifference)
    newFrame = self.window.frame
    newFrame.size.height += heightDifference
    self.window.setFrame(newFrame, display: true, animate: true)    
  end
  
  def toggleUIState
    if startButton.isEnabled
      progressIndicator.startAnimation(self)
      startButton.enabled = false
    else
      progressIndicator.stopAnimation(self)
      startButton.enabled = true
    end
  end
  
  def appsFound(notification)
    self.statusLabel.stringValue = "#{notification.userInfo[:appsCount]} Apps Found"
  end
  
  def processingFinished(notification)
    self.statusLabel.stringValue = "Time to upload ..."
  end
  
  def uploadingStarted(notification)
    self.statusLabel.stringValue = "Uploading ..."
  end
  
  def uploadingFinished(notification)
    self.statusLabel.stringValue = ""
    self.mainText.stringValue = "Thanks for helping the developer community by uploading app data that will help improve and innovate inter-app communication."
    self.secondaryText.stringValue = "And don't forget to tell your friends to scan their iTunes data as well :)" 
    self.startButton.title = "View my results!"
  end
  
  def windowWillClose(sender)
    NSApp.terminate(self)
  end
end

