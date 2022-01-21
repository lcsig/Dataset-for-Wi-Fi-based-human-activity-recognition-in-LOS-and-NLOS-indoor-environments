function data = get_amplitude_sig(csi_file_path)
%   csi_file_path: CSI File Path
%   Output: A struct with 4 fields 
%           (timeStamp, 1stStreamSignals, 2ndStreamSignals, 3rdStreamSignals)
%

    format long;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    subcarriers  = 1:30; 
    streams = 1:3;
    csi_file = read_bf_file(csi_file_path);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Variables
    t = zeros(1, length(csi_file));
    pkt = cell(1, length(csi_file));
    streamMatrix = zeros(length(csi_file), length(subcarriers));
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Returned Data 
    data.timestamp = [];
    data.stream1 = [];
    data.stream2 = [];
    data.stream3 = [];
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Get Tmestamp, Loop on each packet
    shift = 0;
    t(1) = shift + csi_file{1}.timestamp_low;
    for pktStruct = 2:length(csi_file)
        t(pktStruct) = shift + csi_file{pktStruct}.timestamp_low;
        
        % Incase of clock warping
        if t(pktStruct) < t(pktStruct - 1)
            shift = t(pktStruct - 1);
            t(pktStruct) = t(pktStruct) + shift;
            fprintf('Clock Wraping 1 ---> %s\n', csi_file_path);
        end
        if t(pktStruct) - t(pktStruct - 1) > 2000000 % Clock 2*1MHz
            shift = -1 * t(pktStruct) + t(pktStruct - 1);
            t(pktStruct) = t(pktStruct) + shift; % Original Line 
            % t(pktStruct) = t(pktStruct - 1); Edited 11/11/19, Solved With
            % <= sign in the next loop,,, line 67
            fprintf('Clock Wraping 2 ---> %s\n', csi_file_path);
        end
    end
    t = t - t(1);
    
    % Handle Timestamp Repeated Values Issue
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Get if there is repeated values at the end of the time vector
    k = 0;
    for i=length(t):-1:1
       if t(i) == t(i - 1)
            k = k + 1;
       else
           break;
       end
    end
    %
    % Space any repeated values at the end. And make sure
    % That the end of the time vector have no repeated values
    spacing = t(length(t)-k) - t(length(t)-k-1);
    for i=(length(t)- k + 1):length(t)
        t(i) = t(i - 1) + spacing;
    end
    %
    % Space any repeated vales before the end of the time vector
    for i=2:length(t)-1
        if t(i) <= t(i -1) % Edited 11/11/19, MUST BE (<=)
            
            % Get the end of repeated values
            searchEnd = t(i);
            for n=(i+1):length(t)
                if t(n) > searchEnd
                   break; 
                end     
            end
            
            % Space values ...
            t(i-2:n) = linspace(t(i-2), t(n), n - i + 3);
            %t(i) = ((t(i - 1) + t(i + 1)) / 2);
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Finally ...
    data.timestamp = t / 1000000;   % Clock, 1MHz ( 1000000 not 2^20 )
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Loop on each packet, handle and process the SNR values
    parfor pktStruct = 1:length(csi_file)
            csi_scaled = get_scaled_csi(csi_file{pktStruct});
            pkt{pktStruct} = squeeze(csi_scaled(1,:,:)).';
            
            % Loop on each stream
            for strm=streams
                % currentStreamIndexing = tmp{pktStruct}(:, strm);
                pkt{pktStruct}(:, strm) = db(abs(pkt{pktStruct}(:, strm)));
            end
    end
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Loop on each stream
    for streamNo=streams
        % Loop on each subcarrier
        parfor sc=subcarriers
            val = zeros(1, length(csi_file));
            % Loop on each packet struct 
            for pktStruct = 1:length(csi_file)
                val(pktStruct) = pkt{pktStruct}(sc, streamNo);
            end
            streamMatrix(:, sc) = val;
        end
        
        switch (streamNo)
            case 1
                data.stream1 = streamMatrix;
            case 2
                data.stream2 = streamMatrix;
            case 3
                data.stream3 = streamMatrix;
        end
    end
end


