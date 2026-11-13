N = 10000;
a = 1;
r = a/2;
InsideCount = 0;

function MCpiInside = InCircle(x,y,r)
    check = power((x-r),2)+power((y-r),2)-power(r,2);
    MCpiInside = (check <= 0);
end;

tic;

    for i = 1:N
        x = rand();
        y = rand();
        if (InCircle(x,y,r) == 1)
              InsideCount = InsideCount + 1;
        endif;
    end

totalTime = toc;

ApproxPi = 4 * (InsideCount/N);
fprintf("Εκτέλεση για %d σημεία...\n", N);
fprintf("Σημεία στον κύκλο: %d\n", InsideCount);
fprintf("Προσεγγιστική τιμή του π: %.15f\n", ApproxPi);
fprintf("Χρόνος εκτέλεσης προγράμματος: %.3f δευτερόλεπτα\n", totalTime);
