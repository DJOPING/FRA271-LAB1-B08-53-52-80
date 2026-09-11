function S = avgFolder(folder, varargin)
%AVGFOLDER  อ่านไฟล์บันทึกผลทุกไฟล์ในโฟลเดอร์ แล้วเฉลี่ยค่าออกมา
%
%   avgFolder('Magnatic\N20mm')
%       ได้ค่าเฉลี่ยหน่วย LSB และ mV
%
%   avgFolder('Magnatic\N20mm', 'VQ', 1642.83, 'Sens', 33)
%       คำนวณความเข้มสนามแม่เหล็ก B (mT) ให้ด้วย
%       VQ   = แรงดัน baseline (mV) ตอนไม่มีแม่เหล็ก
%       Sens = ความไวเซนเซอร์ (mV/mT)
%
%   avgFolder('Magnatic\N20mm', 'VQ', 'Magnatic\VQ', 'Variant', 'A2')
%       VQ   ใส่เป็น "โฟลเดอร์" ได้ เดี๋ยวไปหาค่าเฉลี่ยจากโฟลเดอร์นั้นเอง
%       Variant = รุ่นย่อย DRV5055 (A1/A2/A3/A4) เปิดตาราง Sens ให้อัตโนมัติ
%
%   S = avgFolder(...)  คืน struct: mean, std, mean_mV, std_mV, B_mT, nRuns, ...

    p = inputParser;
    p.addParameter('VQ',      []);                 % mV หรือ path โฟลเดอร์
    p.addParameter('Sens',    [], @isnumeric);     % mV/mT
    p.addParameter('Variant', 'A2', @(x)ischar(x)||isstring(x));   % DRV5055A2 (ยืนยันจาก part marking 55A2)
    p.addParameter('Vref',    3.3, @isnumeric);    % V
    p.addParameter('TA',      25,  @isnumeric);    % อุณหภูมิแวดล้อม (C)
    p.addParameter('STC',     0.12,@isnumeric);    % %/C จาก datasheet (typ)
    p.addParameter('Quiet',   false, @islogical);
    p.addParameter('Save',    true);                % true / false / ชื่อไฟล์ที่ต้องการ
    p.parse(varargin{:});
    o = p.Results;

    ADCMAX = 4095;                       % ADC 12-bit
    LSB2MV = o.Vref*1000 / ADCMAX;
    % ช่วงแรงดันขาออกที่ยังเป็นเชิงเส้น (datasheet: VL = 0.2 V ถึง VCC-0.2 V)
    VL_LO = 0.2*1000 / LSB2MV;
    VL_HI = (o.Vref-0.2)*1000 / LSB2MV;

    d = [dir(fullfile(folder,'*.mldatx')); dir(fullfile(folder,'*.mat'))];
    d = d(~[d.isdir]);
    if isempty(d)
        error('ไม่พบไฟล์ .mldatx หรือ .mat ในโฟลเดอร์ %s', folder);
    end

    runMeans = [];  runStds = [];  nPts = 0;  nSat = 0;
    for i = 1:numel(d)
        f = fullfile(d(i).folder, d(i).name);
        [~,~,ext] = fileparts(f);
        V = readAll(f, ext);
        for k = 1:numel(V)
            v = V{k};
            v = v(v ~= 0);                          % ตัดจุดเริ่มต้นของ Simulink
            if isempty(v), continue; end
            if mean(v) > VL_HI || mean(v) < VL_LO, nSat = nSat + 1; end
            runMeans(end+1) = mean(v);              %#ok<AGROW>
            runStds(end+1)  = std(v);               %#ok<AGROW>
            nPts = nPts + numel(v);
        end
    end
    if isempty(runMeans)
        error('อ่านข้อมูลไม่ได้เลยจากโฟลเดอร์ %s', folder);
    end

    S.nFiles   = numel(d);
    S.nRuns    = numel(runMeans);
    S.nPoints  = nPts;
    S.mean     = mean(runMeans);
    S.std      = std(runMeans);
    S.noise    = mean(runStds);
    S.mean_mV  = S.mean * LSB2MV;
    S.std_mV   = S.std  * LSB2MV;
    S.runMeans = runMeans;

    % ---------- หาค่า VQ ----------
    VQ = o.VQ;
    S.VQ_source = 'ระบุเป็นตัวเลขโดยตรง';
    if isempty(VQ)
        sib = fullfile(fileparts(folder), 'VQ');      % มองหาโฟลเดอร์ VQ ข้างๆ
        if isfolder(sib) && ~strcmpi(folder, sib)
            VQ = sib;
        end
    end
    if ischar(VQ) || isstring(VQ)
        vqPath = char(VQ);
        Sq = avgFolder(vqPath, 'Vref', o.Vref, 'Quiet', true);
        VQ = Sq.mean_mV;
        S.VQ_source  = vqPath;
        S.VQ_nRuns   = Sq.nRuns;
        S.VQ_std_mV  = Sq.std_mV;
    end

    % ---------- หาค่า Sensitivity ----------
    Sens = o.Sens;
    if isempty(Sens) && ~isempty(o.Variant)
        % ค่าจาก datasheet DRV5055 (SBAS640C) ตาราง Electrical Characteristics
        % typical sensitivity ที่ TA = 25C  -- แยกคอลัมน์ตาม VCC ไม่ใช่สเกลเชิงเส้น
        t33 = struct('A1',60,  'A8',40,   'A2',30, 'A3',15, 'A4',7.5);   % VCC = 3.3 V
        t50 = struct('A1',100, 'A8',66.6, 'A2',50, 'A3',25, 'A4',12.5);  % VCC = 5.0 V
        key = upper(char(o.Variant));
        if abs(o.Vref - 5) < 0.3, tbl = t50; else, tbl = t33; end
        if ~isfield(tbl, key)
            error('Variant ต้องเป็น A1, A2, A3, A4 หรือ A8 (ได้รับ "%s")', key);
        end
        Sens25 = tbl.(key);
        % ชดเชยอุณหภูมิ: Sens = Sens25 * (1 + STC*(TA - 25)),  STC = 0.12 %/C (typ)
        Sens = Sens25 * (1 + (o.STC/100)*(o.TA - 25));
        S.Variant = key;
        S.Sens25  = Sens25;
    end

    if ~isempty(VQ) && ~isempty(Sens)
        S.VQ_mV    = VQ;
        S.Sens     = Sens;
        S.B_mT     = (S.mean_mV - VQ) / Sens;
        S.B_std_mT = S.std_mV / Sens;
    end

    % ---------- บันทึกผลอัตโนมัติเป็นสคริปต์ .m ----------
    if ~o.Quiet && ~isequal(o.Save, false)
        [parent, name] = fileparts(folder);
        if ischar(o.Save) || isstring(o.Save)
            outfile = char(o.Save);
        else
            outfile = fullfile(parent, [name '.m']);
        end
        if ~startsWith(outfile, filesep) && isempty(regexp(outfile, '^[A-Za-z]:', 'once'))
            outfile = fullfile(pwd, outfile);       % ต้องเป็น path เต็ม
        end
        matlab.io.saveVariablesToScript(outfile, 'S');
        S.savedTo = outfile;
    end

    if o.Quiet, return; end

    % ---------- แสดงผล ----------
    [~, name] = fileparts(folder);
    fprintf('\n%s : %d ไฟล์ | %d รอบ | %s จุด\n', name, S.nFiles, S.nRuns, ...
            regexprep(sprintf('%d', nPts), '(\d)(?=(\d{3})+$)', '$1,'));
    fprintf('  mean = %8.2f LSB  = %8.2f mV\n', S.mean, S.mean_mV);
    fprintf('  std  = %8.2f LSB  = %8.2f mV   (ระหว่างรอบ)\n', S.std, S.std_mV);
    fprintf('  noise= %8.2f LSB                (ภายในรอบ)\n', S.noise);
    if isfield(S, 'B_mT')
        fprintf('  B    = %+8.3f mT  (+- %.3f mT)\n', S.B_mT, S.B_std_mT);
        fprintf('         [VQ = %.2f mV, Sens = %.2f mV/mT @ %.0f C]\n', VQ, Sens, o.TA);
    else
        fprintf('  (ใส่ ''VQ'' และ ''Sens'' หรือ ''Variant'' เพื่อให้คำนวณ B เป็น mT)\n');
    end
    if nSat > 0
        fprintf('  !! เตือน: %d รอบหลุดช่วงเชิงเส้น (ต้องอยู่ %.0f - %.0f LSB) ค่าใช้ไม่ได้\n', nSat, VL_LO, VL_HI);
    end
    if S.std > 3*S.noise && S.nRuns > 1
        fprintf('  !! เตือน: ค่าระหว่างรอบต่างกันมากกว่า noise %.0f เท่า อาจมีรอบที่เงื่อนไขไม่ตรงกันปนอยู่\n', S.std/S.noise);
    end
    fprintf('\n');
end

% ----------------------------------------------------------------------
function V = readAll(f, ext)
    V = {};
    if strcmpi(ext, '.mldatx')
        Simulink.sdi.clear;
        Simulink.sdi.load(f);
        ids = Simulink.sdi.getAllRunIDs;
        for k = 1:numel(ids)
            r = Simulink.sdi.getRun(ids(k));
            for i = 1:r.SignalCount
                V{end+1} = double(r.getSignalByIndex(i).Values.Data); %#ok<AGROW>
            end
        end
    else
        D = load(f);
        fn = fieldnames(D);
        for k = 1:numel(fn)
            x = D.(fn{k});
            if isa(x, 'Simulink.SimulationData.Dataset')
                V{end+1} = double(x.getElement(1).Values.Data);       %#ok<AGROW>
            elseif isa(x, 'timeseries')
                V{end+1} = double(x.Data);                            %#ok<AGROW>
            elseif isnumeric(x)
                V{end+1} = double(x(:));                              %#ok<AGROW>
            end
        end
    end
end
