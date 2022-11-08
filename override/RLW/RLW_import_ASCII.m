function [header,data,message_string]=RLW_import_ASCII(filename,epoch_size,sampling_rate,xstart,varargin);
%RLW_import_ASCII
%
%Import ASCII data
%filename : name of ASCII file name
%epoch_size (1000)
%sampling_rate (1000)
%xstart (-0.5)
%
%varargin
%'header_lines' (0)
%'import_channel_labels' (0)
%'channel_label_line' (0)
%'discard_characters_channel_labels' ('")
%'column_delimiters' (' ')
%
% Author : 
% Andre Mouraux
% Institute of Neurosciences (IONS)
% Universite catholique de louvain (UCL)
% Belgium
% 
% Contact : andre.mouraux@uclouvain.be
% This function is part of Letswave 6
% See http://nocions.webnode.com/letswave for additional information
%


header_lines=0;
data = [];
import_channel_labels=0;
channel_label_line=0;
discard_characters_channel_labels='''"';
column_delimiters=' ';


%parse varagin
if isempty(varargin)
else
    %header_lines
    a=find(strcmpi(varargin,'header_lines'));
    if ~isempty(a)
        header_lines=varargin{a+1};
    end
    %import_channel_labels
    a=find(strcmpi(varargin,'import_channel_labels'));
    if ~isempty(a)
        import_channel_labels=varargin{a+1};
    end
    %channel_label_line
    a=find(strcmpi(varargin,'channel_label_line'));
    if ~isempty(a)
        channel_label_line=varargin{a+1};
    end
    %channel_label_line
    a=find(strcmpi(varargin,'discard_characters_channel_labels'));
    if ~isempty(a)
        discard_characters_channel_labels=varargin{a+1};
    end
    %channel_label_line
    a=find(strcmpi(varargin,'column_delimiters'));
    if ~isempty(a)
        column_delimiters=varargin{a+1};
    end
end

%init message_string
message_string={};

%open file
[f,message]=fopen(filename);
if ~isempty(message)
    message_string=message;
end
%skip header lines if header_lines>0
if header_lines>0
    for i=1:channel_label_line
        st=fgetl(f); 
    end

    if import_channel_labels
        channel_string = st;
    end

    for i=channel_label_line+1:header_lines
        st=fgetl(f); %#ok
    end
end
%set channel labels
%if import_channel_labels==0
if import_channel_labels==0
    st=fgetl(f);
    tp=textscan(st,'%s','Delimiter',column_delimiters,'MultipleDelimsAsOne',1);
    numchannels=length(tp{1});
    for i=1:numchannels
        channel_labels{i}=['C' num2str(i)];
    end
else
    tp=textscan(channel_string,'%s','Delimiter',column_delimiters,'MultipleDelimsAsOne',1);
    channel_labels=tp{1};
    numchannels=length(channel_labels);
end
message_string{end+1}=['Number of channels : ',num2str(numchannels)];
message_string{end+1}=['Epoch size : ',num2str(epoch_size)];

frewind(f); %go back to line 1 column 1
%if epoch_size>0, then read epochs
if epoch_size>0
    %read epochs
    epoch_pos=1;
    while not(feof(f))
        [tp,~]=textscan(f,'%n',epoch_size*numchannels,'Headerlines', header_lines, 'Delimiter',column_delimiters,'MultipleDelimsAsOne',1);
        if length(tp{1})==epoch_size*numchannels
            data(epoch_pos,:,1,1,1,:)=reshape(tp{1},numchannels,epoch_size);
            epoch_pos=epoch_pos+1;
        else
            fread(f,1);
        end
    end
else
    %if epoch_size==0, this means that it is continuous data
    [tp,~]=textscan(f,'%n','Headerlines', header_lines, 'Delimiter', column_delimiters,'MultipleDelimsAsOne',1);
    if mod(length(tp{1}),numchannels)==0
        epoch_size=length(tp{1})/numchannels;
        data(1,:,1,1,1,:)=reshape(tp{1},numchannels,epoch_size);
    else
        fread(f,1);
    end
end

%build header
header.filetype='time_amplitude';
[~,n,~]=fileparts(filename);
header.name=n;
header.tags='';
header.datasize= size(data);
header.xstart=xstart;
header.ystart=0;
header.zstart=0;
header.xstep=1/sampling_rate;
header.ystep=1;
header.zstep=1;
message_string{end+1}=['Number of epochs found : ' num2str(header.datasize(1))];
%set chanlocs
%dummy chanloc
chanloc.labels='';
chanloc.topo_enabled=0;
chanloc.SEEG_enabled=0;
%set chanlocs
for chanpos=1:numchannels
    chanloc.labels=strtrim(channel_labels{chanpos});
    header.chanlocs(chanpos)=chanloc;
end;
%delete characters from channel labels if needed
stdel=discard_characters_channel_labels;
if ~isempty(stdel)
    for i=1:length(header.chanlocs)
        st=header.chanlocs(i).labels;
        for j=1:length(stdel)
            st(find(st==stdel(j)))=[];
        end
        header.chanlocs(i).labels=st;
    end
end
header.events=[];
