load('mask.mat');         % 假设变量名为 mask
edgeExtractionFromMat('mask.mat', 'mask');
polarEdgeFeature(mask);   % 调用函数






function polarEdgeFeature(mask)
    % polarEdgeFeature - 以图像中心为原点，提取mask边缘的角度-距离图像特征
    % 输入:
    %   mask - 逻辑图像或灰度图像（边缘区域为前景）

    % 若非逻辑图，先归一化并二值化
    if ~islogical(mask)
        mask = imbinarize(mat2gray(mask));
    end

    % 提取边缘
    edgeMask = edge(mask, 'Sobel');

    % 获取图像尺寸和中心坐标
    [H, W] = size(mask);
    cx = W / 2;
    cy = H / 2;

    % 获取边缘点坐标
    [y, x] = find(edgeMask);  % 注意：y是行，x是列

    % 转换为相对于中心的坐标
    dx = x - cx;
    dy = cy - y;  % 图像坐标系中y向下，因此取负

    % 计算距离和角度
    r = sqrt(dx.^2 + dy.^2);
    theta = atan2(dy, dx);  % [-pi, pi]

    % 将角度转换为 [0, 2pi]，以方便排序
    theta(theta < 0) = theta(theta < 0) + 2*pi;

    % 定义象限索引
    Q1 = dx > 0 & dy >= 0;  % 第一象限
    Q2 = dx <= 0 & dy > 0;  % 第二象限
    Q3 = dx < 0 & dy <= 0;  % 第三象限
    Q4 = dx >= 0 & dy < 0;  % 第四象限

    % 创建角度-距离图像点集合
    angles_all = [];
    distances_all = [];

    for q = 1:4
        switch q
            case 1
                idx = Q1;
            case 2
                idx = Q2;
            case 3
                idx = Q3;
            case 4
                idx = Q4;
        end
        angles = theta(idx);
        distances = r(idx);

        % 按角度排序
        [angles_sorted, sort_idx] = sort(angles);
        distances_sorted = distances(sort_idx);

        angles_all = [angles_all; angles_sorted];
        distances_all = [distances_all; distances_sorted];
    end

    % 可视化结果：二维图，横轴为角度，纵轴为距离
    figure;
    plot(angles_all, distances_all, '.');
    xlabel('角度 (radian)');
    ylabel('距离 (pixel)');
    title('按象限排序的边缘极坐标特征图');
    grid on;
end

function edgeExtractionFromMat(matFilePath, varName)
    % edgeExtractionFromMat - 从 .mat 文件中加载图像数据并提取边缘
    % 输入参数:
    %   matFilePath - .mat 文件路径
    %   varName     - 图像变量名（如 'mask'）

    % 加载图像数据
    data = load(matFilePath);
    
    if ~isfield(data, varName)
        error('变量 %s 不存在于 %s 文件中。', varName, matFilePath);
    end
    
    img = data.(varName);
    
    if ~ismatrix(img)
        error('输入图像必须为灰度图（2D矩阵）。');
    end

    img = im2uint8(mat2gray(img)); % 归一化后转换为 uint8

    % 1. 形态学方法
    se = strel('square', 3);
    dilated = imdilate(img, se);
    edgeMorph = imsubtract(dilated, img);

    % 2. 梯度算子方法
    edgeSobel   = edge(img, 'Sobel');
    edgeRoberts = edge(img, 'Roberts');
    edgePrewitt = edge(img, 'Prewitt');

    % 显示结果
    figure('Name', 'Edge Extraction from .mat');
    subplot(2,3,1); imshow(img); title('原始图像');
    subplot(2,3,2); imshow(edgeMorph); title('形态学边缘');
    subplot(2,3,4); imshow(edgeSobel); title('Sobel 边缘');
    subplot(2,3,5); imshow(edgeRoberts); title('Roberts 边缘');
    subplot(2,3,6); imshow(edgePrewitt); title('Prewitt 边缘');
end


