% =========================================================================
% โค้ดวิเคราะห์สัญญาณ Incremental Encoder (Phase A & B)
% =========================================================================
clc; clear; close all;

filename = 'testPPR.mat'; % <-- เปลี่ยนชื่อไฟล์ตรงนี้ตามรอบที่คุณเซฟมา
S = load(filename);

fprintf('\n=== 📊 สรุปผลการทดลองจากไฟล์: %s ===\n', filename);

% 1. ค้นหาและดึงข้อมูลสัญญาณ (รองรับโครงสร้าง Dataset ของ Simulink)
queue = {S}; names_queue = {'S'};
time_array = []; sigA = []; sigB = [];

while ~isempty(queue)
    current = queue{1}; cname = names_queue{1};
    queue(1) = []; names_queue(1) = [];
    
    if isa(current, 'Simulink.SimulationData.Dataset')
        for i = 1:current.numElements
            elem = current.getElement(i); queue{end+1} = elem;
            if isprop(elem, 'Name') && ~isempty(elem.Name), names_queue{end+1} = elem.Name;
            else, names_queue{end+1} = sprintf('Sig_%d', i); end
        end
    elseif isa(current, 'Simulink.SimulationData.Signal') && isprop(current, 'Values')
        queue{end+1} = current.Values; names_queue{end+1} = current.Name;
    elseif isa(current, 'timeseries')
        data_val = double(squeeze(current.Data));
        time_val = double(squeeze(current.Time));
        % คัดแยกสัญญาณ A และ B (อิงจากชื่อ A0, A1 หรือสุ่มเอา 2 เส้นแรกที่เจอ)
        if contains(lower(cname), 'a0') || isempty(sigA)
            sigA = data_val; time_array = time_val;
        elseif contains(lower(cname), 'a1') || isempty(sigB)
            sigB = data_val;
        end
    elseif isstruct(current)
        fields = fieldnames(current);
        for i = 1:numel(fields)
            queue{end+1} = current.(fields{i}); names_queue{end+1} = fields{i};
        end
    end
end

% 2. ประมวลผลและวิเคราะห์พฤติกรรม
if ~isempty(sigA) && ~isempty(sigB)
    % แปลงสัญญาณเป็นดิจิทัล (0 และ 1) เพื่อลดสัญญาณรบกวน
    threshA = min(sigA) + 0.5 * (max(sigA) - min(sigA));
    threshB = min(sigB) + 0.5 * (max(sigB) - min(sigB));
    digitalA = sigA > threshA;
    digitalB = sigB > threshB;
    
    % หาขอบขาขึ้น (Rising Edge) ของ Phase A
    edgesA = find(diff(digitalA) == 1);
    
    if length(edgesA) >= 2
        % --- วิเคราะห์ทิศทาง (CW/CCW) ---
        % เช็คสถานะของ Phase B ณ จังหวะที่ Phase A กำลังเป็นขาขึ้น
        check_idx = edgesA(2); % ใช้ขอบที่ 2 เพื่อเลี่ยงคลื่นกวนตอนเริ่มต้น
        stateB_at_edgeA = digitalB(check_idx);
        
        if stateB_at_edgeA == 0
            direction = 'CW (ตามเข็มนาฬิกา)';
            phase_lead = 'Phase A นำหน้า Phase B';
        else
            direction = 'CCW (ทวนเข็มนาฬิกา)';
            phase_lead = 'Phase B นำหน้า Phase A';
        end
        
        % --- วิเคราะห์ความเร็ว ---
        % คำนวณคาบเวลาเฉลี่ย (Period) และความถี่ (Frequency)
        periods = diff(time_array(edgesA));
        avg_period = mean(periods);
        freq = 1 / avg_period;
        
        if freq < 10, speed_lvl = 'ช้า (Low Speed)';
        elseif freq < 50, speed_lvl = 'ปานกลาง (Medium Speed)';
        else, speed_lvl = 'เร็ว (High Speed)'; end
        
        % แสดงผลลัพธ์บน Command Window
        fprintf(' -> ทิศทางการหมุน: %s\n', direction);
        fprintf(' -> ความสัมพันธ์: %s\n', phase_lead);
        fprintf(' -> ความเร็วเฉลี่ย: %.2f Hz (%s)\n', freq, speed_lvl);
        fprintf('====================================================\n\n');
        
        % 3. พล็อตตีกราฟ Phase Shift ลงรายงาน
        figure('Name', 'Encoder Phase Analysis', 'Color', 'w');
        % ยก Phase A ขึ้นไปข้างบนนิดนึง เพื่อไม่ให้กราฟทับกัน (Offset)
        offset = 1.5;
        plot(time_array, digitalA + offset, 'LineWidth', 2, 'Color', [0 0.4470 0.7410]); hold on;
        plot(time_array, digitalB, 'LineWidth', 2, 'Color', [0.8500 0.3250 0.0980]);
        
        % ตกแต่งกราฟให้ดูโปร
        ylim([-0.5, 3]);
        xlim([time_array(edgesA(1))-0.05, time_array(edgesA(end))+0.05]);
        yticks([0 1 offset offset+1]);
        yticklabels({'B: Low', 'B: High', 'A: Low', 'A: High'});
        title(sprintf('สัญญาณ Encoder - หมุน %s (%.1f Hz)', direction, freq), 'FontSize', 14);
        xlabel('เวลา (วินาที)', 'FontSize', 12);
        grid on;
        legend('Phase A (A0)', 'Phase B (A1)', 'Location', 'northeast');
        
    else
        disp('ไม่พบรูปคลื่นมากพอที่จะคำนวณครับ ลองหมุนให้นานขึ้นอีกนิด');
    end
else
    disp('ดึงสัญญาณ A0 และ A1 ไม่สำเร็จ ตรวจสอบการตั้งค่า To Workspace ครับ');
end