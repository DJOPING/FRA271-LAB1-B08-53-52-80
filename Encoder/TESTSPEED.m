% =======================================================
% โค้ดเปรียบเทียบจลนศาสตร์ 2 ระดับความเร็ว (ช้า vs เร็ว)
% =======================================================
clc; close all;
% รันรอบหมุนช้าเสร็จ: slow_pos = out.pos_rad; slow_vel = out.vel_rad;

% รันรอบหมุนเร็วเสร็จ: fast_pos = out.pos_rad; fast_vel = out.vel_rad;
figure('Name', 'Kinematics: Slow vs Fast', 'Color', 'w', 'Position', [150, 150, 900, 450]);

% --- ช่องที่ 1: Position (เทียบความชันระยะทาง) ---
subplot(1, 2, 1);
plot(slow_pos.Time, slow_pos.Data, 'b', 'LineWidth', 2.5); hold on;
plot(fast_pos.Time, fast_pos.Data, 'r', 'LineWidth', 2.5);
title('Position (rad) - เทียบความชัน', 'FontSize', 12);
xlabel('Time (s)'); ylabel('Radian');
legend('หมุนช้า (Slow)', 'หมุนเร็ว (Fast)', 'Location', 'NorthWest');
grid on; hold off;

% --- ช่องที่ 2: Velocity (เทียบความเร็วพีก) ---
subplot(1, 2, 2);
% ใช้ smoothdata เกลี่ย Noise เล็กน้อยให้กราฟสวยขึ้น
plot(slow_vel.Time, smoothdata(slow_vel.Data, 'movmean', 10), 'b', 'LineWidth', 1.5); hold on;
plot(fast_vel.Time, smoothdata(fast_vel.Data, 'movmean', 10), 'r', 'LineWidth', 1.5);
title('Velocity (rad/s) - เทียบความเร็วเชิงมุม', 'FontSize', 12);
xlabel('Time (s)'); ylabel('rad/s');
legend('หมุนช้า (Slow)', 'หมุนเร็ว (Fast)', 'Location', 'NorthWest');
grid on; hold off;

% --- สรุปตัวเลขลง Command Window ---
fprintf('=== 📊 สรุปผลทดสอบความเร็ว (ช้า vs เร็ว) ===\n');
fprintf('[หมุนช้า] ความเร็วพีกสุด: %6.2f rad/s | ตำแหน่งจบ: %6.2f rad\n', max(abs(slow_vel.Data)), slow_pos.Data(end));
fprintf('[หมุนเร็ว] ความเร็วพีกสุด: %6.2f rad/s | ตำแหน่งจบ: %6.2f rad\n', max(abs(fast_vel.Data)), fast_pos.Data(end));
disp('=============================================');