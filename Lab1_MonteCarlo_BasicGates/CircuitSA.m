function CircuitSA()
  printf("Signal Probability Analysis for Circuit:\n");
  printf("d = (a AND b) AND NOT(c)\n\n");

  % Θεωρούμε πιθανότητες εισόδων (για άγνωστο φόρτο εργασίας, θεωρούμε 0.5)
  a_sp = 0.5;
  b_sp = 0.5;
  c_sp = 0.5;

  printf("Input probabilities: P(a=1)=%f, P(b=1)=%f, P(c=1)=%f\n\n", a_sp, b_sp, c_sp);

  % Υπολογισμός ενδιάμεσων σημάτων
  e_sp = sp2AND(a_sp, b_sp);
  f_sp = spNOT(c_sp);
  d_sp = sp2AND(e_sp, f_sp);

  printf("Intermediate and output probabilities:\n");
  printf("P(e=1) = P(a AND b=1) = %f\n", e_sp);
  printf("P(f=1) = P(NOT(c)=1) = %f\n", f_sp);
  printf("P(d=1) = P(e AND f=1) = %f\n\n", d_sp);

  % Υπολογισμός switching activity (α = P * (1-P))
  e_sw = e_sp * (1 - e_sp);
  f_sw = f_sp * (1 - f_sp);
  d_sw = d_sp * (1 - d_sp);

  printf("Switching activities:\n");
  printf("e_sw = %f\n", e_sw);
  printf("f_sw = %f\n", f_sw);
  printf("d_sw = %f\n", d_sw);
end

function s = sp2AND(input1sp, input2sp)
  s = input1sp * input2sp;
end

function s = sp2OR(input1sp, input2sp)
  s = 1 - (1 - input1sp) * (1 - input2sp);
end

function s = spNOT(input1sp)
  s = 1 - input1sp;
end
