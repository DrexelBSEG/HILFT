function [scores]=Function_Performance_score(Powerset,Power,baseline,regulation_capacity)

A(:,1)=Powerset;
A(:,2)=Power;

B=A(1:1:end,:);
B=(B-baseline)/regulation_capacity;

[row,column]=size(B);

for i=1:(row-59)
    
    a=B(i:i+29,1);
    
  for j=0:30
    
    d=B(i+j:i+29+j,2);
    c(j+1,1)=min(min(corrcoef(a,d)));
    
  end
    [x,y]=max(c);
    Delay_Score(i,1)=abs(((y-1)*10-300)/300);
    Correlation_Score(i,1)=x;
  
      
end

  aa=B(1:row,1);
    Error_total=0;
    for m=1:(row-1)
        Error=abs((B(m,1)-B(m+1,2))/(mean(abs(aa))));
        Error_total=Error+Error_total;
    end
        
    Precision_Score=1-Error_total/row;



Delay_Score_av=mean(Delay_Score);    
Correlation_Score_av=mean(Correlation_Score);


result(:,1)=Correlation_Score_av;
result(:,2)=Delay_Score_av;
result(:,3)=Precision_Score;
result(:,4)=(Correlation_Score_av+Delay_Score_av+Precision_Score)/3;
scores=result;

end


