function circuit_sim()
  printf("Truth Table for Circuit using gate functions:\n");
  printf("d = (a AND b) AND NOT(c)\n\n");
  printf("a  b  c | e=AND(a,b)  f=NOT(c) | d=AND(e,f)\n");
  printf("------------------------------------------\n");

  for a = 0:1
    for b = 0:1
      for c = 0:1

        e = sp2AND(a, b);
        f = spNOT(c);
        d = sp2AND(e, f);

        printf("%d  %d  %d |      %d          %d    |    %d\n", a, b, c, e, f, d);

      end
    end
  end

end

function s=sp2AND(input1sp, input2sp)
  printf("AND Gate for input probabilities (%f %f):\n",input1sp,input2sp)
  s = input1sp*input2sp;
endfunction
function s=sp2OR(input1sp, input2sp)
  printf("OR Gate for input probabilities (%f %f):\n",input1sp,input2sp)
  s = 1-(1-input1sp)*(1-input2sp);
endfunction
function s=spNOT(input1sp)
  printf("мот Gate for input probabilities (%f):\n",input1sp)
  s = 1 - input1sp;
endfunction
