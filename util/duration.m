function y = duration(arr)
  
hh = arr(1);
mm = arr(2);
ss = arr(3);

y = hh * 3600 + mm * 60 + ss;