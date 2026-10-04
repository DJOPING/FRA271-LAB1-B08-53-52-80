% ==========================================
% 1. ดึงข้อมูลจาก Simulink
% ==========================================
t = out.raw_data.Time; 

raw_count = out.raw_data.Data;           % Hardware_Raw_65535
rel_pulse = out.unwrapped_data.Data;     % Unwrapped_Pulse (Relative Pulse)
pos_rad   = out.pos_data.Data;           % Position_Rad
vel_rads  = out.vel_data.Data;           % Velocity_Rad_s

% ==========================================
% 2. พล็อตกราฟ 3 ช่อง
% ==========================================
figure('Name', 'CW/CCW & Wrap-around Analysis', 'Position', [100, 100, 1000, 800]);

% --- ช่องที่ 1: โชว์การแก้ Wrap-around (Raw vs Relative Pulse) ---
subplot(3, 1, 1);
yyaxis left;
plot(t, raw_count, 'r', 'LineWidth', 1.5);
ylabel('Raw Count (0-65535)');
ylim([-5000 70000]); 

yyaxis right;
plot(t, rel_pulse, 'b', 'LineWidth', 2, 'LineStyle', '--');
ylabel('Relative Pulse');

title('1. Wrap-around Prevention: Raw Data vs Relative Pulse');
legend('Hardware Raw', 'Unwrapped (Relative) Pulse', 'Location', 'best');
grid on;

% --- ช่องที่ 2: โชว์ตำแหน่ง (Radians) และทิศทาง CW/CCW ---
subplot(3, 1, 2);
plot(t, pos_rad, 'g', 'LineWidth', 2);
title('2. Position (Radians) - สังเกตทิศทาง CW และ CCW');
ylabel('Position (rad)');
grid on;

% --- ช่องที่ 3: โชว์ความเร็ว (rad/s) ---
subplot(3, 1, 3);
plot(t, vel_rads, 'm', 'LineWidth', 1.5);
title('3. Velocity (rad/s) - ความเร็วเชิงมุม');
xlabel('Time (s)');
ylabel('Velocity (rad/s)');
grid on;

