function s=signalprobs3(input1sp, input2sp, input3sp)
  sp3AND(input1sp, input2sp, input3sp)
  sp3OR(input1sp, input2sp, input3sp)
  sp3XOR(input1sp, input2sp, input3sp)
  sp3NAND(input1sp, input2sp, input3sp)
  sp3NOR(input1sp, input2sp, input3sp)
end

function s=sp3AND(input1sp, input2sp, input3sp)
  printf("AND Gate for input probabilities (%f %f %f):\n",input1sp,input2sp,input3sp)
  s = input1sp*input2sp*input3sp;
endfunction

function s=sp3OR(input1sp, input2sp, input3sp)
  printf("OR Gate for input probabilities (%f %f %f):\n",input1sp,input2sp,input3sp)
  s = 1-(1-input1sp)*(1-input2sp)(1-input3sp);
endfunction

function s=sp3XOR(input1sp, input2sp)
  printf("XOR Gate for input probabilities (%f %f %f):\n",input1sp,input2sp,input3sp)
  s = input1sp*(1 - input2sp)*(1 - input3sp) + input2sp*(1 - input3sp)*(1 - input1sp) + (1 - input1sp)*(1 - input2sp)*input3sp + input1sp*input2sp*input3sp;
endfunction

function s=sp3NAND(input1sp, input2sp, input3sp)
  printf("NAND Gate for input probabilities (%f %f %f):\n",input1sp,input2sp,input3sp)
  s = 1 - (input1sp * input2sp * input3sp);
endfunction

function s=sp3NOR(input1sp, input2sp, input3sp)
  printf("NOR Gate for input probabilities (%f %f %f):\n",input1sp,input2sp,input3sp)
  s = (1 - input1sp) * (1 - input2sp) * (1 - input3sp);
endfunction
