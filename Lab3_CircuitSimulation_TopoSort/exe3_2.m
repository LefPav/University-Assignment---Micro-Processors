% Uses global SignalsTable, process(element) and ElementsTable with numeric indices.
% Then parses them, detects top inputs (both methods), simulates truth table,
% computes Esw from truth table, and does probabilistic propagation for p=0.5 and p=0.1234.

global SignalsTable;

% Primitive gate helpers
function s = spAND(varargin)
  temp = 1;
  for i = 1:nargin
    temp = temp * varargin{i};
  endfor
  s = temp;
endfunction

function s = spNOT(x)
  s = 1 - x;
endfunction

% process(element) - simulation step
% element.type: string
% element.inputs: vector of numeric indices
% element.output: numeric index
function process(element)
  global SignalsTable;
  t = upper(element.type);
  if strcmp(t,'AND')
    v = spAND(SignalsTable(element.inputs(1)), SignalsTable(element.inputs(2)));
    SignalsTable(element.output) = v;
  elseif strcmp(t,'NOT')
    v = spNOT(SignalsTable(element.inputs(1)));
    SignalsTable(element.output) = v;
  else
    printf("Unsupported element type in process(): %s\n", element.type);
  endif
endfunction

% Compute Esw from binary sequence
function Esw = ComputeEsw(seq)
  n = length(seq);
  if n <= 1
    Esw = 0;
    return;
  endif
  sw = 0;
  for i = 2:n
    if seq(i) != seq(i-1)
      sw = sw + 1;
    endif
  endfor
  Esw = sw / (n-1);
endfunction

% Parser for Format 2 files
% Returns:
%  - ElementsTable : cell array of element structs (fields: type, inputs_names, output_name)
%  - signals_names  : cell array of all signal names (strings)
%  - declared_top_inputs : cell array of names if top_inputs line present, else {}
function [ElementsTable, signals_names, declared_top_inputs] = parse_circuit_file(filename)
  fid = fopen(filename, 'r');
  if fid < 0
    error(['Cannot open file: ', filename]);
  end
  Elements_tmp = {};
  signals_list = {}; % accumulate names, may contain duplicates
  declared_top_inputs = {};
  line_no = 0;
  while true
    tline = fgetl(fid);
    if ~ischar(tline)
      break;
    endif
    line_no = line_no + 1;
    s = strtrim(tline);
    if isempty(s)
      continue;
    endif
    % skip comments (lines starting with // or #)
    if startsWith(s, '//') || startsWith(s, '#')
      continue;
    endif
    tokens = strsplit(s);
    if isempty(tokens)
      continue;
    endif
    tok0 = lower(tokens{1});
    if strcmp(tok0, 'top_inputs')
      declared_top_inputs = tokens(2:end);
      % ensure they are in signals_list too
      for k = 1:numel(declared_top_inputs)
        signals_list{end+1} = declared_top_inputs{k};
      endfor
      continue;
    end
    % Format 2: GATE OUT IN1 IN2 ...
    gate = upper(tokens{1});
    outname = tokens{2};
    inames = tokens(3:end);
    elem.type = gate;
    elem.output_name = outname;
    elem.input_names = inames;
    Elements_tmp{end+1} = elem;
    % add to signals list
    signals_list{end+1} = outname;
    for k = 1:numel(inames)
      signals_list{end+1} = inames{k};
    endfor
  endwhile
  fclose(fid);

  % unique signals, preserve insertion order
  signals_names = {};
  for k = 1:numel(signals_list)
    name = signals_list{k};
    if ~any(strcmp(signals_names, name))
      signals_names{end+1} = name;
    endif
  endfor

  % return ElementsTable with names for now; will resolve to indices later
  ElementsTable = Elements_tmp;
endfunction

% Build index mapping and convert ElementsTable to numeric-index form
% Inputs:
%  - ElementsTable (with names)
%  - signals_names (cell array of names)
% Outputs:
%  - ElementsIdx: cell array of elements with numeric indices: .type, .inputs (vector idx), .output (idx)
%  - name2idx : containers.Map name->index
%  - idx2name : cell array index->name (same as signals_names)
function [ElementsIdx, name2idx, idx2name] = build_indexed_elements(ElementsTable, signals_names)
  idx2name = signals_names;
  name2idx = containers.Map();
  for i = 1:numel(idx2name)
    name2idx(idx2name{i}) = i;
  endfor
  ElementsIdx = {};
  for e = 1:numel(ElementsTable)
    elem = ElementsTable{e};
    E.type = elem.type;
    % convert input names to indices (assume 2-input for binary gates, or 1 for NOT; support variable)
    inames = elem.input_names;
    inds = zeros(1, numel(inames));
    for k = 1:numel(inames)
      if isKey(name2idx, inames{k})
        inds(k) = name2idx(inames{k});
      else
        % if name wasn't in signals (rare), add it
        newidx = numel(idx2name) + 1;
        idx2name{end+1} = inames{k};
        name2idx(inames{k}) = newidx;
        inds(k) = newidx;
      endif
    endfor
    E.inputs = inds;
    % output
    if isKey(name2idx, elem.output_name)
      E.output = name2idx(elem.output_name);
    else
      newidx = numel(idx2name) + 1;
      idx2name{end+1} = elem.output_name;
      name2idx(elem.output_name) = newidx;
      E.output = newidx;
    endif
    ElementsIdx{end+1} = E;
  endfor
endfunction

% Detect top inputs:
% If declared_top_inputs not empty -> use those (return list of names)
% Else -> automatic: top inputs are signals that are never written by any element
function top_names = detect_top_inputs_decl_or_auto(ElementsIdx, idx2name, declared_top_inputs)
  if ~isempty(declared_top_inputs)
    top_names = declared_top_inputs;
    return;
  end
  % build set of writers
  writers = zeros(1, numel(idx2name));
  for e = 1:numel(ElementsIdx)
    out = ElementsIdx{e}.output;
    writers(out) = 1;
  endfor
  top_names = {};
  for i = 1:numel(idx2name)
    if writers(i) == 0
      top_names{end+1} = idx2name{i};
    endif
  endfor
endfunction

% Simulate truth table for given top_inputs (names)
% elements are in ElementsIdx (numeric)
% returns history: matrix signals_count x T (rows = signals indices)
function history = simulate_truth_table(ElementsIdx, idx2name, top_inputs_names)
  S = numel(idx2name);
  n_top = numel(top_inputs_names);
  % map top names to indices
  % build name->idx map
  name2idx = containers.Map();
  for i = 1:S
    name2idx(idx2name{i}) = i;
  endfor
  top_indices = zeros(1,n_top);
  for k=1:n_top
    top_indices(k) = name2idx(top_inputs_names{k});
  endfor
  T = 2^n_top;
  history = zeros(S, T);
  for t = 0:(T-1)
    % compute bits for each top input; MSB-first mapping
    for k = 1:n_top
      bpos = n_top - k;
      history(top_indices(k), t+1) = bitget(t, bpos+1);
    endfor
    % initialize other signals to 0 for this time-step
    % apply elements in order; use global SignalsTable
    global SignalsTable;
    SignalsTable = zeros(1, S);
    % set top inputs
    for k=1:n_top
      idx = top_indices(k);
      SignalsTable(idx) = history(idx, t+1);
    endfor
    % evaluate elements in file order (assumes file sorted)
    for e = 1:numel(ElementsIdx)
      process(ElementsIdx{e}); % will read/write global SignalsTable
    endfor
    % store all signals at this time
    for s = 1:S
      history(s, t+1) = SignalsTable(s);
    endfor
  endfor
endfunction

% Compute Esw per signal from history matrix (S x T)
function Esw_vec = Esw_from_history(history)
  [S, T] = size(history);
  Esw_vec = zeros(S,1);
  for s = 1:S
    seq = history(s, :);
    Esw_vec(s) = ComputeEsw(seq);
  endfor
endfunction

% Probabilistic propagation (assumes elements in correct order)
% Input:
%  - ElementsIdx (numeric)
%  - idx2name (cell array)
%  - top_inputs_names (cell)
%  - p_top_vals (vector matching top_inputs_names)
% Output:
%  - pvec (vector length S) with p(signal==1)
function pvec = probabilistic_propagation(ElementsIdx, idx2name, top_inputs_names, p_top_vals)
  S = numel(idx2name);
  pvec = zeros(S,1);
  % build name->idx
  name2idx = containers.Map();
  for i = 1:S
    name2idx(idx2name{i}) = i;
  endfor
  % set top input probabilities
  for k = 1:numel(top_inputs_names)
    nm = top_inputs_names{k};
    if isKey(name2idx, nm)
      pvec(name2idx(nm)) = p_top_vals(k);
    else
      % name not present (shouldn't happen) -> add?
      warning(['Top input not in signals: ', nm]);
    endif
  endfor
  % propagate through elements in order
  for e = 1:numel(ElementsIdx)
    E = ElementsIdx{e};
    typ = upper(E.type);
    ins = E.inputs;
    switch typ
      case 'NOT'
        pvec(E.output) = 1 - pvec(ins(1));
      case 'AND'
        prodp = 1;
        for k = 1:numel(ins)
          prodp = prodp * pvec(ins(k));
        endfor
        pvec(E.output) = prodp;
      otherwise
        warning(['Unsupported gate type in probabilistic_propagation: ', typ]);
    endswitch
  endfor
endfunction

% Helper: print Esw vector nicely with signal names
function print_esw_vec(Esw_vec, idx2name)
  for i=1:numel(idx2name)
    printf(' %s : %.6f\n', idx2name{i}, Esw_vec(i));
  endfor
endfunction

% TESTBENCH
% Creates two example files and runs parser + detection + sim
function testbench_3_2()
  printf('\n--- Testbench Exe3_2: file loading + top_inputs detection ---\n');

  % create example with top_inputs line (Method A)
  fnameA = 'circuit_with_top.txt';
  fid = fopen(fnameA,'w');
  fprintf(fid, 'top_inputs a b c\n');
  fprintf(fid, 'AND e a b\n');
  fprintf(fid, 'NOT f c\n');
  fprintf(fid, 'AND d e f\n');
  fclose(fid);

  % create example without top_inputs (Method B)
  fnameB = 'circuit_no_top.txt';
  fid = fopen(fnameB,'w');
  fprintf(fid, 'AND e a b\n');
  fprintf(fid, 'NOT f c\n');
  fprintf(fid, 'AND d e f\n');
  fclose(fid);

  filelist = {fnameA, fnameB};
  for fi = 1:numel(filelist)
    fn = filelist{fi};
    printf('\n--- Processing file: %s ---\n', fn);
    [Elems, signals_names, declared_top] = parse_circuit_file(fn);
    [ElemsIdx, name2idx, idx2name] = build_indexed_elements(Elems, signals_names);
    top_names = detect_top_inputs_decl_or_auto(ElemsIdx, idx2name, declared_top);

    printf('Signals found: ');
    disp(idx2name);
    if ~isempty(declared_top)
      printf('Declared top_inputs: ');
      disp(declared_top);
    else
      printf('No declared top_inputs in file.\n');
    endif
    printf('Detected top inputs to use: ');
    disp(top_names);

    % Simulate truth table
    history = simulate_truth_table(ElemsIdx, idx2name, top_names);
    Esw_vec = Esw_from_history(history);
    printf('\nEsw from truth-table workload:\n');
    print_esw_vec(Esw_vec, idx2name);

    % Probabilistic p=0.5
    p_top = ones(1, numel(top_names)) * 0.5;
    pvec = probabilistic_propagation(ElemsIdx, idx2name, top_names, p_top);
    Esw_p = 2 * pvec .* (1 - pvec);
    printf('\nProbabilistic propagation (p=0.5) estimates (p and Esw):\n');
    for i=1:numel(idx2name)
      printf(' %s : p=%.6f  Esw_est=%.6f\n', idx2name{i}, pvec(i), Esw_p(i));
    endfor

    % Probabilistic p=0.5332
    p_top2 = ones(1, numel(top_names)) * 0.5332;
    pvec2 = probabilistic_propagation(ElemsIdx, idx2name, top_names, p_top2);
    Esw_p2 = 2 * pvec2 .* (1 - pvec2);
    printf('\nProbabilistic propagation (p=0.5332) estimates (p and Esw):\n');
    for i=1:numel(idx2name)
      printf(' %s : p=%.6f  Esw_est=%.6f\n', idx2name{i}, pvec2(i), Esw_p2(i));
    endfor

  endfor

  printf('\nTestbench Exe3_2 complete.\n');
endfunction

testbench_3_2();
