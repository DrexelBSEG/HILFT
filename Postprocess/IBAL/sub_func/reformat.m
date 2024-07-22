function output = reformat(input, desired_size)

% Transpose if needed
if size(input,1) < size(input,2)
    input = input';
end

% Reformat cell to structure
num_of_fields = 0;
if iscell(input)
    for i = 1:length(input)
        if length(fieldnames(input{i,1})) < num_of_fields
            continue;
        end
        temp(i,1) = input{i,1};
        num_of_fields = length(fieldnames(input{i,1}));
    end
    input = temp;
end

% Size the array
if length(input) > desired_size
    output = input(1:desired_size,1);
elseif length(input) < desired_size
    index_end = length(input);
    for i = index_end+1:desired_size
        input(i,1) = input(i-1,1);
    end
    output = input(1:desired_size,1);
else
    output = input;
end

end

