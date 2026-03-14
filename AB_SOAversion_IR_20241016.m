function [] = AB_SOAversion_IR_20241016()
clearvars; close all; clc;
%% Get subject information
expinfo   = [];
dlgprompt = {'Subject ID:',...
             'Age:',...
             'Seq:',...
             'Target color:'};
dlgname       = 'Sub&Exp Information';
numlines      = 1;
defaultanswer = {'S20','0','1 2 2 1','0'}; % 20241016改
ans1          = inputdlg(dlgprompt,dlgname,numlines,defaultanswer);
expinfo.id      = ans1{1};
expinfo.age     = str2num(ans1{2});
expinfo.seq     = str2num(ans1{3}); % 20241016改
expinfo.tarcolr = [0 str2num(ans1{4}) 0];

expinfo.stdura    = 6;%6 frames = 100ms when the fresh rate is 60 Hz
expinfo.stimdura  = 2;
expinfo.visangle  = 1.5;
expinfo.backcolr  = [0;0;0];
expinfo.instcolr  = [105;105;105];

expinfo.seqlength = 18; 
expinfo.withnblk  = 60 * 1;%rest for 1 minutes


sexStrList    = {'Female','Male'};
handStrList   = {'Right','Left'};
[sexidx,v]    = listdlg('PromptString','Gender:','SelectionMode','Single','ListString',sexStrList);
expinfo.sex   = sexStrList{sexidx};
if ~v; expinfo.sex  = 'NA'; end
[handidx,v]   = listdlg('PromptString','Handedness:','SelectionMode','Single','ListString',handStrList);
expinfo.hand  = handStrList{handidx};
if ~v; expinfo.hand = 'NA'; end

% Key assignment
KbName('UnifyKeyNames');
spaceKey   = KbName('space');
enterKey   = KbName('return');
quitKey    = KbName('escape');
respKey1   = KbName('7');
respKey2   = KbName('8');
respKey3   = KbName('9');
respKey4   = KbName('4');
respKey5   = KbName('5');
respKey6   = KbName('6'); 
respKey7   = KbName('1');
respKey8   = KbName('2');
respKey9   = KbName('3'); 
respKeys1  = [respKey1, respKey2, respKey3, respKey4, respKey5, respKey6, respKey7, respKey8, respKey9]; %respKeys
while KbCheck; end
ListenChar(2);

% set the conditions in random
%seq = [1 1 2 2];%1=valid cue;2=no cue
expinfo.sequence = expinfo.seq; % 20241016改

% Set the folder and filename for data save
destdir = './SOA_interval/posttest/';
if ~exist(destdir,'dir'), mkdir(destdir); end
expinfo.path2save = strcat(destdir,expinfo.id,'post_',mfilename,'_',datestr(now,30));

data = [];
data.expinfo = expinfo;
save(expinfo.path2save,'data');

% set other parameters
viewDistance = 600; % viewing distance (mm)
whichScreen  = 0; % screen index for use
winRect      = []; % initial window size, empty indicates a whole screen window
pixelDepth   = 32;
numBuffer    = 2;
stereoMode   = 0;
multiSample  = 0;
imagingMode  = [];
%% Standard coding practice, use try/catch to allow cleanup on error.
try
    % This script calls Psychtoolbox commands available only in
    % OpenGL-based versions of Psychtoolbox. The Psychtoolbox command
    % AssertPsychOpenGL will issue an error message if someone tries to
    % execute this script on a computer without an OpenGL Psychtoolbox.
    AssertOpenGL;  
    
    % Screen is able to do a lot of configuration and performance checks on
	% open, and will print out a fair amount of detailed information when
	% it does. These commands supress that checking behavior and just let
    % the program go straight into action. See ScreenTest for an example of
    % how to do detailed checking.
	oldVisualDebugLevel = Screen('Preference','VisualDebugLevel',3);
    oldSupressAllWarnings = Screen('Preference','SuppressAllWarnings',1);
    
    % Open a screen window and get window information.
    [winPtr, winRect] = Screen('OpenWindow',whichScreen,expinfo.backcolr,winRect,pixelDepth,numBuffer,stereoMode,multiSample,imagingMode);
    Screen('BlendFunction',winPtr,GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
    Screen('TextSize',winPtr,35);
    Screen('TextFont',winPtr,'Kaiti');
    [x0,y0] = RectCenter(winRect);
    ifi = Screen('GetFlipInterval',winPtr);
    [width_mm, height_mm] = Screen('DisplaySize', whichScreen);
    screenSize    = [width_mm, height_mm];
    winResolution = [winRect(3)-winRect(1),winRect(4)-winRect(2)];
    ppd = viewDistance*tan(pi/180)*winResolution./screenSize;
    ppd = round(ppd);
    stimsize = ppd(1)*expinfo.visangle;
    ovalsize = ppd(1)*expinfo.visangle*1.5;
        
    % Hide mouse curser and set the priority level
    HideCursor;
    priorityLevel = MaxPriority(winPtr);
    Priority(priorityLevel);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % TASK SESSION
    lettlist  = 'ABCDFGHJKMNPQRSTUVWXYZ';%n=22去掉E，O，I，L
    T1loc     = repmat([5 6 7],1,6);   T2loc = [1 2 3 4 5 6 7 8]; % repmat 函数用于重复数组,它将向量 [5 6 7] 重复6次，形成一个6行3列的矩阵。
    [S1,S2]   = ndgrid(T1loc,T2loc);
    SS        = [S1(:) S2(:)];
    textstr2  = ['请在呈现序列中找到两个绿色字母，\n'...
        '序列结束后立刻回答并按回车键确认，\n'...
        '如果不小心输错请按空格键清空答案。\n'...
        '明白要求后请按空格键开始任务。'];
    textstr3  = ['每组开始会呈现一条线段\n'...
        '提示你本次任务两个目标的时间间隔。\n'...
        '线段呈现结束后会出现“+”字注视点\n'...
        '“+”字注视点消失后呈现刺激序列。'];
    textstr4  = '请按顺序输入两个绿色字母:';
    
    for n = 1:length(lettlist)
        Lett{n}   = imread(['.\stim\' lettlist(n) '.png'],'png');
        for i     = 1:size(Lett{n},1)
            for j = 1:size(Lett{n},2)
                if Lett{n}(i,j,1:3) ~= expinfo.backcolr
                    Lett{n}(i,j,1:3) = expinfo.instcolr;
                end
            end
        end
    end
    
    % prepare for the fix figure
    Crossfix = imread(['.\stim\' num2str(1) '.png'],'png');
    for i = 1:size(Crossfix,1)
        for j = 1:size(Crossfix,2)
            if Crossfix(i,j,1:3) ~= expinfo.backcolr
                Crossfix(i,j,1:3) = expinfo.instcolr;
            end
        end
    end
    textCrossfix = Screen('MakeTexture',winPtr,Crossfix);
    % No cue condition  * fix
    fix = imread(['.\stim\' num2str(4) '.png'],'png');
    for i = 1:size(fix,1)
        for j = 1:size(fix,2)
            if fix(i,j,1:3) ~= expinfo.backcolr
                fix(i,j,1:3) = expinfo.instcolr;
            end
        end
    end
    textfix = Screen('MakeTexture',winPtr,fix);
    
    [~,~,alpha] = imread('.\stim\Oval.png','png');
    oval        = MaskImageIn(alpha);
    for i = 1:size(oval,1)
        for j = 1:size(oval,2)
            if oval(i,j,1:3) ~= expinfo.backcolr
                oval(i,j,1:3) = expinfo.instcolr;
            end
        end
    end
    textoval  = Screen('MakeTexture',winPtr,oval);
    %% experimental measurement
    flag   = 0;
    for blk = 1:length(expinfo.sequence)  % 4 blk
        SS    = SS(randperm(size(SS,1)),:); % randperm(size(SS,1)) SS中第一维度的所有数据做随机，SS(randperm(size(SS,1)),:)  使用上一步生成的随机排列向量作为行索引，选择 SS 的行
        
        % present the instruction
        textstr1    = ['正式测试第' num2str(blk) '组:'];
        BoundsRect1 = Screen('TextBounds',winPtr,double(textstr1));
        DrawFormattedText(winPtr,double(textstr1),x0-400-(BoundsRect1(3)-BoundsRect1(1))/2,y0-300-(BoundsRect1(4)-BoundsRect1(2))/2,expinfo.instcolr);
        BoundsRect2 = RectOfMatrix(double(textstr2));
        DrawFormattedText(winPtr,double(textstr2),x0-350-(BoundsRect2(3)-BoundsRect2(1))/2,y0-200-(BoundsRect2(4)-BoundsRect2(2))/2,expinfo.instcolr,[],[],[],2);
        if expinfo.sequence(blk) == 1
            BoundsRect3 = RectOfMatrix(double(textstr3));
            DrawFormattedText(winPtr,double(textstr3),x0-350-(BoundsRect3(3)-BoundsRect3(1))/2,y0+200-(BoundsRect3(4)-BoundsRect3(2))/2,expinfo.instcolr,[],[],[],2);
        end
        Screen('Flip',winPtr)
        while 1
            [keydown, ~, keycode] = KbCheck;
            if keydown
                while KbCheck; end
                if keycode(spaceKey)|| keycode(quitKey); break; end  
            end
        end
        Screen('FillRect',winPtr,expinfo.backcolr);
        Screen('Flip',winPtr);
        if keycode(quitKey); break; end
        
        % start each trial
        trlT          = 0;
        for trl = 1:size(SS,1)
            T1pos = SS(trl,1);
            T2pos = SS(trl,2);
            lettlist_perm  = Shuffle(lettlist);
            lettlist_perm  = lettlist_perm(1:expinfo.seqlength);
            T1lett = Lett{ismember(lettlist,lettlist_perm(T1pos))};
            T2lett = Lett{ismember(lettlist,lettlist_perm(T1pos+T2pos))};
            
            numstim  = expinfo.stimdura;%frame of stim
            numISI   = expinfo.stdura-numstim;
            for i = 1:size(T1lett,1)
                for j = 1:size(T1lett,2)
                    if T1lett(i,j,1:3) ~= expinfo.backcolr
                        T1lett(i,j,1:3) = expinfo.tarcolr;
                    end
                end
            end
            for i = 1:size(T2lett,1)
                for j = 1:size(T2lett,2)
                    if T2lett(i,j,1:3) ~= expinfo.backcolr
                        T2lett(i,j,1:3) = expinfo.tarcolr;
                    end
                end
            end
            textt1 = Screen('MakeTexture',winPtr,T1lett);
            textt2 = Screen('MakeTexture',winPtr,T2lett);
            
            ISIframe = length(lettlist_perm);
            ISIseq   = repmat(numISI,1,ISIframe);
            
            if expinfo.sequence(blk) == 1
                lineLength = T2pos;
                lineWidth = 7;
                singleLineLength = 1 * ppd(1); % single Segment length
                gapLength = 0.2 * ppd(1); % Segment interval length
                totalLengthWithGaps = (singleLineLength * lineLength) + (lineLength - 1) * gapLength;
                for i = 1:lineLength
                    startX = x0 - (totalLengthWithGaps / 2) + ((i - 1) * (singleLineLength + gapLength));
                    endX = startX + singleLineLength;
                    Screen('DrawLine', winPtr, [105,105,105], startX, y0, endX, y0, lineWidth);
                end
            else
               Screen('DrawTexture',winPtr,textfix,[],[x0-stimsize/2,y0-stimsize/2,x0+stimsize/2,y0+stimsize/2]);  
            end
            Screen('Flip', winPtr);
            WaitSecs(2);
            Screen('DrawTexture',winPtr,textCrossfix,[],[x0-stimsize/2,y0-stimsize/2,x0+stimsize/2,y0+stimsize/2]);
            Screen('Flip', winPtr);
            WaitSecs(0.8);
                
            time1 = GetSecs; % 记录整个刺激呈现开始的时间点 
            tpoint = []; ISI = [];
            for stim = 1:length(lettlist_perm)
                isi1 = GetSecs;
                for num = 1:ISIseq(stim)
                    Screen('FillRect',winPtr,expinfo.backcolr);
                    Screen('DrawTexture',winPtr,textoval,[],[x0-ovalsize/2,y0-ovalsize/2,x0+ovalsize/2,y0+ovalsize/2]);
                    Screen('Flip',winPtr);% Screen time of background
                end
                isi2 = GetSecs; ISI = [ISI isi2-isi1]; isi1 = isi2;
                textlett = Screen('MakeTexture',winPtr,Lett{ismember(lettlist,lettlist_perm(stim))});
                Screen('DrawTexture',winPtr,textlett,[],[x0-stimsize/2,y0-stimsize/2,x0+stimsize/2,y0+stimsize/2]);
                if stim == T1pos
                    Screen('DrawTexture',winPtr,textt1,[],[x0-stimsize/2,y0-stimsize/2,x0+stimsize/2,y0+stimsize/2]);
                    time2 = GetSecs; tpoint = [tpoint time2-time1];
                    % 在特定条件下（stim == T1pos 或 stim == T1pos+T2pos）获取，记录特定刺激呈现的时间点，并将其与 time1 的差值存储在 tpoint 数组中。
                    % 分别保存T1和T2呈现的时间
                elseif stim == T1pos+T2pos
                    Screen('DrawTexture',winPtr,textt2,[],[x0-stimsize/2,y0-stimsize/2,x0+stimsize/2,y0+stimsize/2]);
                    time2 = GetSecs; tpoint = [tpoint time2-time1];
                end
                Screen('DrawTexture',winPtr,textoval,[],[x0-ovalsize/2,y0-ovalsize/2,x0+ovalsize/2,y0+ovalsize/2]);
                for num = 1:numstim-1
                    Screen('Flip',winPtr,0,1);%前面几帧呈现完不消失
                end
                Screen('Flip',winPtr);%最后一帧呈现完消失
            end
            time3 = GetSecs;  % 记录整个刺激呈现结束的时间点
                       
             % wait for a response
            resp = []; resptime = []; xlocation = []; ylocation = []; resphistory = []; textshown = [];
            BoundsRect4   = Screen('TextBounds',winPtr,double(textstr4));
            DrawFormattedText(winPtr,double(textstr4),x0-(BoundsRect4(3)-BoundsRect4(1))/2,y0-200-(BoundsRect4(4)-BoundsRect4(2))/2,expinfo.instcolr);
            
          
            if T2pos <= 4  % ？？？有改动
                shownstim = Shuffle(lettlist_perm(T1pos+T2pos-4:T1pos+T2pos+4));
            else
                shownstim = Shuffle([lettlist_perm(T1pos-1:T1pos+2) lettlist_perm(T1pos+T2pos-2:T1pos+T2pos+2)]);
            end
            for num = 1:9
                textlett = Screen('MakeTexture',winPtr,Lett{ismember(lettlist,shownstim(num))});
                if num <= 3
                    Screen('DrawTexture',winPtr,textlett,[],[x0+(num-2)*100-stimsize/2,y0-100-stimsize/2,x0+(num-2)*100+stimsize/2,y0-100+stimsize/2]);
                elseif num <= 6
                    Screen('DrawTexture',winPtr,textlett,[],[x0+(num-5)*100-stimsize/2,y0-stimsize/2,x0+(num-5)*100+stimsize/2,y0+stimsize/2]);
                elseif num <= 9
                    Screen('DrawTexture',winPtr,textlett,[],[x0+(num-8)*100-stimsize/2,y0+100-stimsize/2,x0+(num-8)*100+stimsize/2,y0+100+stimsize/2]);
                end
            end
            Screen('Flip',winPtr);
            bodyimage = Screen('GetImage',winPtr,[]);
            texbody   = Screen('MakeTexture',winPtr,bodyimage);
            
            while 1
                [keydown, secs, keycode] = KbCheck;
                if keydown && numel(find(keycode)) == 1
                    while KbCheck; end
                    if numel(find(find(keycode) == respKeys1)) == 1
                        target        = find(find(keycode) == respKeys1);
                        resp          = [resp shownstim(target)];
                        resptime      = [resptime secs-time3];
                        resphistory   = [resphistory shownstim(target)];
                        if (0 < target)&&(target < 4)
                            xlocation = [xlocation x0+(target-2)*100];
                            ylocation = [ylocation y0-100];
                        elseif (3 < target)&&(target < 7)
                            xlocation = [xlocation x0+(target-5)*100];
                            ylocation = [ylocation y0];
                        elseif (6 < target)&&(target < 10)
                            xlocation = [xlocation x0+(target-8)*100];
                            ylocation = [ylocation y0+100];
                        end
                        shownlett = Lett{ismember(lettlist,shownstim(target))};
                        for i = 1:size(shownlett,1)
                            for j = 1:size(shownlett,2)
                                if shownlett(i,j,:) ~= expinfo.backcolr
                                    shownlett(i,j,:) = expinfo.tarcolr;
                                end
                            end
                        end
                        textshown = [textshown Screen('MakeTexture',winPtr,shownlett)];
                    elseif keycode(spaceKey)
                        xlocation = []; ylocation = []; resp = []; textshown =[];
                    end
                    
                    respmax = 2;
                    if length(resp) > respmax %超过最大值无法继续输入
                        resptime  = resptime(1:end+respmax-length(resp)); resphistory = resphistory(1:end+respmax-length(resp));
                        xlocation = xlocation(1:respmax); ylocation = ylocation(1:respmax); resp = resp(1:respmax); textshown = textshown(1:2);
                    elseif length(resp) == respmax && respmax == 2 %同一个字母输入两次只算一次
                        if resp(1) == resp(2)
                            resp      = resp(1); textshown = textshown(1);
                            xlocation = xlocation(1);
                            ylocation = ylocation(1);
                        end
                    end
                    
                    Screen('PreloadTextures',winPtr,texbody);
                    Screen('DrawTexture',winPtr,texbody);
                    for r = 1:length(resp)
                        Screen('DrawTexture',winPtr,textshown(r),[],[xlocation(r)-stimsize/2,ylocation(r)-stimsize/2,xlocation(r)+stimsize/2,ylocation(r)+stimsize/2]);
                    end
                    Screen('Flip',winPtr);
                    if (keycode(enterKey)&&length(resp) == respmax)||(keycode(quitKey)); break; end
                end
            end
            if keycode(quitKey);break; end
                       
            % save all the results after each trial 
            data.lettseq{blk}{trl,:}      = lettlist_perm;
            data.lett{blk}(trl,:)         = [lettlist_perm(T1pos) lettlist_perm(T1pos+T2pos)];
            data.T1T2pos{blk}{trl,:}      = [T1pos T2pos];
            data.resp{blk}(trl,:)         = resp;
            data.resptime{blk}{trl,:}     = resptime;
            data.resphistory{blk}{trl,:}  = resphistory;
            data.letttime{blk}(trl,:)     = time3-time1; % 当前试次从刺激开始呈现到最后一个刺激消失整体的时间
            data.T1T2time{blk}(trl,:)     = tpoint; % 这里有改动 data.T1T2point{i,blk}(trl(i,blk),:)   = tpoint;
                                                    % 将T1和T2对应出现的时间点储存在tpoint中
            data.ISI{blk}{trl,:}          = ISI;
            save(expinfo.path2save,'data');
            
            trlT = trlT + 1 ;
            if trlT == 36
                textstr6    = '请稍作休息,休息结束后，请按空格键自行开始';
                BoundsRect6 = Screen('TextBounds',winPtr,double(textstr6));
                Screen('FillRect',winPtr,expinfo.backcolr);
                DrawFormattedText(winPtr,double(textstr6),x0-50-(BoundsRect6(3)-BoundsRect6(1))/2,y0-(BoundsRect6(4)-BoundsRect6(2))/2,expinfo.instcolr);
                Screen('Flip',winPtr);
                while 1
                    [keydown, ~, keycode] = KbCheck;
                    if keydown
                        while KbCheck; end
                        if keycode(spaceKey)|| keycode(quitKey); break; end
                    end
                end
                trlT = 0;
            end
            
            Screen('FillRect',winPtr,expinfo.backcolr);
            Screen('Flip',winPtr);
        end

        Screen('FillRect',winPtr,expinfo.backcolr);
        vbl = Screen('Flip',winPtr);
        frames4break = floor(expinfo.withnblk);
        if blk < length(expinfo.sequence)
            for m = 1:frames4break
                showTmin1 = floor(floor((expinfo.withnblk-(m-1))/60)/10);
                showTmin2 = rem(floor((expinfo.withnblk-(m-1))/60),10);
                showTsec1 = floor(rem(expinfo.withnblk-(m-1),60)/10);
                showTsec2 = rem(rem(expinfo.withnblk-(m-1),60),10);
                DrawFormattedText(winPtr,double('请休息一会儿'),150,y0-50,expinfo.instcolr);
                Screen('DrawText',winPtr,[num2str(showTmin1) num2str(showTmin2) ':' num2str(showTsec1) num2str(showTsec2)],150,y0+50,expinfo.instcolr);
                vbl = Screen('Flip',winPtr,vbl+(1/ifi-0.5)*ifi);
                [~, ~, keycode] = KbCheck;
                if keycode(quitKey);flag = 1; break;end
            end
        end
        if flag == 1; break; end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % The end statement of the experiment
    DrawFormattedText(winPtr,double('实验结束。'),150,y0-40,expinfo.instcolr);
    DrawFormattedText(winPtr,double('非常感谢！'),150,y0+40,expinfo.instcolr);
    Screen('Flip',winPtr);
    WaitSecs(2.0);
    Screen('FillRect',winPtr,expinfo.backcolr);
    Screen('Flip',winPtr);
    Screen('CloseAll');
    ShowCursor;
    fclose('all');
    Priority(0);
    
    % Restore preferences
    Screen('Preference', 'VisualDebugLevel', oldVisualDebugLevel);
    Screen('Preference', 'SuppressAllWarnings', oldSupressAllWarnings);
    ListenChar(0);
    
catch
    % Catch error.
    Screen('FillRect',winPtr,expinfo.backcolr);
    Screen('Flip',winPtr);
    Screen('CloseAll');
    ShowCursor;
    fclose('all');
    Priority(0);
    % Restore preferences
    Screen('Preference', 'VisualDebugLevel', oldVisualDebugLevel);
    Screen('Preference', 'SuppressAllWarnings', oldSupressAllWarnings);
    ListenChar(0);
    psychrethrow(psychlasterror);
end % try ... catch %