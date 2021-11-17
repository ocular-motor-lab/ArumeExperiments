classdef VOG  < handle
    %VOG Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        eyeTracker
    end
    
    methods
        function result = Connect(this, ip, port)
           result = 0;
           
            if ( ~exist('port','var') )
                port = 9000;
            end
                        
            if ( exist('C:\secure\Code\EyeTracker\bin\x64\Debug','file') )
                asm = NET.addAssembly('C:\secure\Code\EyeTracker\bin\x64\Debug\EyeTrackerRemoteClient.dll');
                if ( ~exist('ip','var') )
                    ip = fileread('C:\secure\Code\EyeTracker\bin\x64\Debug\IP.txt');
                end
            elseif exist('C:\secure\EyeTracker Debug 2018-22-08\EyeTrackerRemoteClient.dll')
                asm = NET.addAssembly('C:\secure\EyeTracker Debug 2018-22-08\EyeTrackerRemoteClient.dll');
                if ( ~exist('ip','var') )
                    ip = fileread('C:\secure\EyeTracker Debug 2018-22-08\IP.txt');
                end
            elseif exist('C:\Secure\EyeTracker\Debug\EyeTrackerRemoteClient.dll')
                asm = NET.addAssembly('C:\Secure\EyeTracker\Debug\EyeTrackerRemoteClient.dll');
                if ( ~exist('ip','var') )
                    ip = fileread('C:\Secure\EyeTracker\Debug\IP.txt');
                end
            elseif exist('C:\secure\OpenIris 1.3.7752.29719\Debug\EyeTrackerRemoteClient.dll')
                asm = NET.addAssembly('C:\secure\OpenIris 1.3.7752.29719\Debug\EyeTrackerRemoteClient.dll');
                if ( ~exist('ip','var') )
                    ip = fileread('C:\secure\OpenIris 1.3.7752.29719\Debug\IP.txt');
                end
            elseif exist('C:\Users\jorge\UC Berkeley\OMlab - JOM\Code\EyeTracker\bin\x64\Debug\EyeTrackerRemoteClient.dll')
                asm = NET.addAssembly('C:\Users\jorge\UC Berkeley\OMlab - JOM\Code\EyeTracker\bin\x64\Debug\EyeTrackerRemoteClient.dll');
                if ( ~exist('ip','var') )
                    ip = fileread('C:\Users\jorge\UC Berkeley\OMlab - JOM\Code\EyeTracker\bin\x64\Debug\IP.txt');
                end
            else
                asm = NET.addAssembly('C:\secure\code\Debug\EyeTrackerRemoteClient.dll');
                
                if ( ~exist('ip','var') )
                    ip = fileread('C:\secure\code\Debug\IP.txt');
                end
            end
            
%             this.eyeTracker = VORLab.VOG.Remote.EyeTrackerClient(ip, port);
            this.eyeTracker = OpenIris.EyeTrackerClient(ip, port);
            
            result = 1;
        end
        
        function result = IsRecording(this)
            status = this.eyeTracker.Status;
            result = status.Recording;
        end
        
        function SetSessionName(this, sessionName)
            if ( ~isempty( this.eyeTracker) )
                this.eyeTracker.ChangeSetting('SessionName',sessionName);
            end
        end
        
        function StartRecording(this)
            if ( ~isempty( this.eyeTracker) )
                this.eyeTracker.StartRecording();
            end
        end
        
        function StopRecording(this)
            if ( ~isempty( this.eyeTracker) )
                this.eyeTracker.StopRecording();
            end
        end
        
        function frameNumber = RecordEvent(this, message)
            frameNumber = [];
            if ( ~isempty( this.eyeTracker) )
                frameNumber = this.eyeTracker.RecordEvent([num2str(GetSecs) ' ' message]);
                frameNumber = double(frameNumber);
            end
        end
        
        function [files]= DownloadFile(this, path)
            files = [];
            if ( ~isempty( this.eyeTracker) )
                try
                    files = this.eyeTracker.DownloadFile();
                catch ex
                    ex
                end
                files = cell(files.ToArray)';
            end
        end
    end
    
    methods(Static = true)
        
    end
    
end



