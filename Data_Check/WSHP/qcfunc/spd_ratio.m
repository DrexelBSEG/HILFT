function [y]=spd_ratio(vdc)
    % Comp Speed Ratio Coefficients (vdc>=2.42)
    m1=(1-0.317)/(4.91-2.42);
    b1=0.317-2.42*m1;
    % Comp Speed Ratio Coefficients (vdc<2.42)
    m2=0.317/2.42;
    % Initialize Containers
    y=zeros(length(vdc),1);
    for i=1:length(vdc)
        if vdc(i)>=2.42
            m=m1;
            b=b1;
        else
            m=m2;
            b=0;
        end
        y(i)=m.*vdc(i)+b; % Compressor Speed [0,1]
    end
end