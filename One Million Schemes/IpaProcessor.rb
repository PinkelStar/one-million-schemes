#
#  IpaProcessor.rb
#  One Million Schemes
#
#  Created by Josh Kalderimis on 4/19/11.
#  Copyright 2011 Zwapp. All rights reserved.
#

class IpaProcessor
  
  IPA_FILES_DIR = File.expand_path("~/Music/iTunes/Mobile Applications/*.ipa")
  
  APP_PLIST_LOCATION    = 'Payload/*.app/Info.plist'
  
  ITUNES_META_FILE_NAME = 'iTunesMetadata.plist'
  
  IPA_GCD_GROUP = Dispatch::Group.new
  
  
  attr_reader :appList, :failures
  
  
  def self.updateApps(&block)
    me = self.new
    me.updateApps(&block)
    me.appList
  end

  def initialize
    @appList  = []
    @failures = []
    @queue = Dispatch::Queue.concurrent(:high)
  end
  
  def updateApps(&block)
    appIpas = Dir[IPA_FILES_DIR]
  
    updateStatus("AppsFound", { :appsCount => appIpas.count })
  
    appIpas.each do |ipaFile|
      @queue.async(IPA_GCD_GROUP) { openAndProcessIpa(ipaFile) }
    end
  
    IPA_GCD_GROUP.notify(@queue) do
      Dispatch::Queue.main.async { block.call(self.appList) }
      updateStatus("ProcessingFinished")
    end
  
    true
  end

  private

  def updateStatus(name, userInfo = {})
    nc = NSNotificationCenter.defaultCenter
    nc.postNotificationName(name, object: self, userInfo: userInfo)
  end

  def openAndProcessIpa(ipaFile)
    ipaName  = /Mobile\ Applications\/(.+)/.match(ipaFile)[1]

    rawPlist = openZip(ipaFile, ITUNES_META_FILE_NAME)
  
    unless rawPlist.nil? || rawPlist == ''
      appHash  = processRawPlist(rawPlist)
      appPlist = openAndProcessAppSpecificPlist(ipaFile)
    
      appDetails = {
        :itunes_meta => appHash,
        :app_plist   => appPlist
      }
    
      @appList << appDetails
    else
      logFailure(:noPlistFound, ipaFile)
    end
  rescue StandardError => e
    logFailure(:errorProcessingIpa, ipaFile, e)
  end

  def openAndProcessAppSpecificPlist(ipaFile)
    rawPlist = openZip(ipaFile, APP_PLIST_LOCATION)
  
    unless rawPlist.nil? || rawPlist == ''
      processRawPlist(rawPlist)
    else
      logFailure(:noAppPlistFound, ipaFile)
    end
  end

  def openZip(ipaFile, fileToExtract)
    if `unzip -l '#{ipaFile}' '#{fileToExtract}'`.include?('1 file')
      `unzip -qq -p '#{ipaFile}' '#{fileToExtract}'`
    end
  end

  def processRawPlist(rawPlist)
    error = Pointer.new(:object)
  
    plistHash = NSPropertyListSerialization.propertyListWithData(rawPlist.to_data,
                                                          options: NSPropertyListImmutable,
                                                          format: nil,
                                                          error: error)
  
    raise error[0].userInfo if error[0]
  
    plistHash
  end

  def logFailure(reason, ipaFile, error = nil)
    self.failures << {
      :reason => reason,
      :ipaFile => ipaFile,
      :error => error
    }
  end

end