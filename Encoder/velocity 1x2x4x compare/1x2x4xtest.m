% ==========================================
% 1. ดึงข้อมูลความเร็วจาก Workspace
% ==========================================
t = out.vel_1x.Time; 

v1 = out.vel_1x.Data;
v2 = out.vel_2x.Data;
v4 = out.vel_4x.Data;

% ==========================================
% 2. พล็อตกราฟเปรียบเทียบ
% ==========================================
figure('Name', 'Resolution Comparison: 1X vs 2X vs 4X', 'Position', [100, 100, 800, 500]);

% พล็อตเส้นทับกันเพื่อให้เห็นความต่างของความละเอียด
plot(t, v1, 'g', 'LineWidth', 1.2); hold on;
plot(t, v2, 'b', 'LineWidth', 1.2);
plot(t, v4, 'r', 'LineWidth', 1.5);

title('Velocity Resolution Comparison');
xlabel('Time (s)');
ylabel('Velocity (rad/s)');
legend('1X (PPR = 2014)', '2X (PPR = 4028)', '4X (PPR = 8056)', 'Location', 'best');
grid on; hold off;