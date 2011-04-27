#
#  AppDelegate.rb
#  One Million Schemes
#
#  Created by Josh Kalderimis on 4/19/11.
#  Copyright 2011 Zwapp. All rights reserved.
#

class AppDelegate
  attr_accessor :window, :twitterPromptWindow
  attr_accessor :progressIndicator, :startButton, :statusLabel
  attr_accessor :twitterName, :errorLabel
  attr_accessor :notificationCenter
  
  def applicationDidFinishLaunching(notification)
    setupNotificationsObservers
  end
  
  def setupNotificationsObservers
    @notificationCenter = NSNotificationCenter.defaultCenter
    
    @notificationCenter.addObserver(self,
                                    selector: "appsFound:",
                                    name: "AppsFound",
                                    object: nil)
    
    @notificationCenter.addObserver(self,
                                    selector: "processingFinished:",
                                    name: "ProcessingFinished",
                                    object: nil) 
    
    @notificationCenter.addObserver(self,
                                    selector: "uploadingFinished:",
                                    name: "UploadingFinished",
                                    object: nil) 
  end
  
  def startUpload(sender)
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
    self.twitterName.stringValue = nil
    uploadAppList
  end
  
  def uploadWithTwitterName(sender)
    NSApp.endSheet(twitterPromptWindow)
    TwitterNameChecker.start(self.twitterName.stringValue) do |valid|
      if valid
        uploadAppList
      else
        self.errorLabel.stringValue = "can't seem to find it"
        promptForTwitterName
      end
    end
  end
  
  def didEndSheet(sheet, returnCode: returnCode, contextInfo: contextInfo)
    sheet.orderOut(self)
  end
  
  def uploadAppList
    PlistUploader.start(@recentAppList, self.twitterName.stringValue) do
      @notificationCenter.postNotificationName("UploadingFinished", object: self)
      toggleUIState
    end
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
  
  def uploadingFinished(notification)
    self.statusLabel.stringValue = "All Done!"
  end
  
  def windowWillClose(sender)
    NSApp.terminate(self)
  end
end

