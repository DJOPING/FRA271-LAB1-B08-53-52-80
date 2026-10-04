% ==========================================================
% โค้ดสะสมข้อมูลทีละค่า ทุกครั้งที่กด Run Simulink
% ==========================================================

% 1. ดึงค่าล่าสุดจาก out.Raw, out.Voltage, out.Grams
if isa(out.Raw, 'timeseries')
    curr_raw     = out.Raw.Data(end);
    curr_voltage = out.Voltage.Data(end);
    curr_grams   = out.Grams.Data(end);
else
    curr_raw     = out.Raw(end);
    curr_voltage = out.Voltage(end);
    curr_grams   = out.Grams(end);
end

% 2. ตรวจสอบว่ามีลิสต์เก็บสะสมหรือยัง ถ้ายังไม่มีให้สร้างลิสต์ว่างขึ้นมา
if ~exist('Raw_List', 'var'),     Raw_List = [];     end
if ~exist('Voltage_List', 'var'), Voltage_List = []; end
if ~exist('Grams_List', 'var'),   Grams_List = [];   end

% 3. นำค่าปัจจุบันไปต่อท้ายลิสต์เดิม (Append)
Raw_List     = [Raw_List; curr_raw];
Voltage_List = [Voltage_List; curr_voltage];
Grams_List   = [Grams_List; curr_grams];

% 4. หากสะสมเกิน 10 ค่า ให้ดึงเฉพาะ 10 ค่าล่าสุดไว้
if length(Raw_List) > 10
    Raw_List     = Raw_List(end-9:end);
    Voltage_List = Voltage_List(end-9:end);
    Grams_List   = Grams_List(end-9:end);
end

% 5. แสดงผลตารางสรุปใน Command Window
fprintf('\n[บันทึกสำเร็จ] สะสมข้อมูลแล้ว %d/10 ครั้ง\n', length(Raw_List));
disp(table(Raw_List, Voltage_List, Grams_List, 'VariableNames', {'Raw', 'Voltage', 'Grams'}));