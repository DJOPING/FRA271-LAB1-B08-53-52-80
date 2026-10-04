% ==========================================
% 1. ดึงข้อมูลจาก Simulink (Timeseries)
% ==========================================
t = out.raw_1x.Time; 

raw_count = out.raw_1x.Data;
unwrapped_pulse = out.unwrapped_1x.Data;

% ==========================================
% 2. พล็อตกราฟ: พิสูจน์การแก้ Wrap-around (Overflow/Underflow)
% ==========================================
figure('Name', 'Hardware Limit vs Software Unwrapping', 'Position', [100, 100, 800, 500]);

% แกน Y ฝั่งซ้าย (สีแดง): โชว์ข้อมูลดิบจากฮาร์ดแวร์ที่จะกระโดดเมื่อล้น
yyaxis left;
plot(t, raw_count, 'r', 'LineWidth', 1.5);
ylabel('Hardware Raw Count (0 - 65535)');
ylim([-5000 70000]); % ขยายสเกลบนล่างนิดหน่อยให้เห็นตอนมันชนขอบ 0 และ 65535 ชัดๆ

% แกน Y ฝั่งขวา (สีน้ำเงิน): โชว์ข้อมูลที่ผ่านโค้ด Unwrapping แล้ว
yyaxis right;
plot(t, unwrapped_pulse, 'b', 'LineWidth', 2, 'LineStyle', '--');
ylabel('Unwrapped Pulse (Relative Pulse)');

title('Wrap-around Effect: Raw Data vs Unwrapped Pulse');
xlabel('Time (s)');
legend('Raw Count', 'Unwrapping Pulse', 'Location', 'best');
grid on;

% ==========================================
% 3. สรุปผลทาง Command Window
% ==========================================
fprintf('\n=== 📊 สรุปผลการทดสอบ Wrap-around ===\n');
fprintf('ค่า Raw ต่ำสุด: %d | สูงสุด: %d (สังเกตการชนขอบ 0 หรือ 65535)\n', min(raw_count), max(raw_count));
fprintf('ค่า Unwrapped ต่ำสุด: %d | สูงสุด: %d (วิ่งทะลุขอบได้อย่างอิสระ)\n', min(unwrapped_pulse), max(unwrapped_pulse));
disp('=============================================');
% === 📊 สรุปผลการทดสอบ Wrap-around ===
% ค่า Raw ต่ำสุด: 0 | สูงสุด: 64995 (สังเกตการชนขอบ 0 หรือ 65535)
% ค่า Unwrapped ต่ำสุด: 0 | สูงสุด: 4.634551e+01 (วิ่งทะลุขอบได้อย่างอิสระ)
% =============================================

