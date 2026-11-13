function MCCircuit()
  student_id = 5227;

  % Διανύσματα μεγέθους 10, 100, 5227
  sizes = [10, 100, student_id];

  for s = 1:length(sizes)
    n = sizes(s);
    printf("\n=== Monte Carlo Simulation with %d patterns ===\n", n);

    % Δημιουργία τυχαίων εισόδων
    a_inputs = randi([0, 1], 1, n);
    b_inputs = randi([0, 1], 1, n);
    c_inputs = randi([0, 1], 1, n);

    % Πίνακες για αποθήκευση αποτελεσμάτων
    e_outputs = zeros(1, n);
    f_outputs = zeros(1, n);
    d_outputs = zeros(1, n);

    % Μετρητές για switching activity
    e_switches = 0;
    f_switches = 0;
    d_switches = 0;

    % Προσομοίωση
    for i = 1:n
      % Λογικές πύλες
      e_outputs(i) = and_gate(a_inputs(i), b_inputs(i));
      f_outputs(i) = not_gate(c_inputs(i));
      d_outputs(i) = and_gate(e_outputs(i), f_outputs(i));

      % Υπολογισμός switching activity (μετά από τον πρώτο κύκλο)
      if i > 1
        if e_outputs(i) ~= e_outputs(i-1)
          e_switches = e_switches + 1;
        end
        if f_outputs(i) ~= f_outputs(i-1)
          f_switches = f_switches + 1;
        end
        if d_outputs(i) ~= d_outputs(i-1)
          d_switches = d_switches + 1;
        end
      end
    end

    % Υπολογισμός probabilities και switching activities
    e_prob = sum(e_outputs) / n;
    f_prob = sum(f_outputs) / n;
    d_prob = sum(d_outputs) / n;

    e_sw_activity = e_switches / (n-1);
    f_sw_activity = f_switches / (n-1);
    d_sw_activity = d_switches / (n-1);

    % Εκτύπωση αποτελεσμάτων
    printf("Results for n = %d:\n", n);
    printf("Signal Probabilities:\n");
    printf("  P(e=1) = %.4f\n", e_prob);
    printf("  P(f=1) = %.4f\n", f_prob);
    printf("  P(d=1) = %.4f\n", d_prob);
    printf("Switching Activities:\n");
    printf("  sw_e = %.4f\n", e_sw_activity);
    printf("  sw_f = %.4f\n", f_sw_activity);
    printf("  sw_d = %.4f\n", d_sw_activity);
    printf("Theoretical P(d=1) should be: 0.1250\n");
  end
end

function result = and_gate(input1, input2)
  result = input1 & input2;
end

function result = not_gate(input1)
  result = ~input1;
end



MCCircuit();

