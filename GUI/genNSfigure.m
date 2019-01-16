% set inputs
x = (-40:0.5:40)'; % input data, should load from original data, note to remove missing values
a = 0.5;
b = 0;
c = 40;
covName = 'diseAge';

% identify the display range
xboarder = ceil(max(abs(x-b)));
xub = ceil(b+xboarder);
xlb = floor(b-xboarder);

xx = linspace(xlb, xub, 1000);
yy = nstran(xx,a,b,c);

y = nstran(x,a,b,c);

hold on
plot(xx,yy,'b')
plot(x,y,'bo')

qlx = invnstran(-c*0.99, a, b, c); % lower 99% quantile
qux = invnstran(c*0.99, a, b, c); % upper 99% quantile

xlim([xlb, xub]);
ylim([-c c]);

plot([b b],ylim,'b--')
plot([qlx qlx], ylim, 'r-');
plot([qux, qux], ylim, 'r-');

delta = (xub-xlb)*0.01;

infoStr=cell(3,1);
infoStr{3}=sprintf('\\leftarrow %s=%.2f (dash line)',covName,b);
nx_99 = sum(x<=qux & x>=qlx);
ntotal = length(x);
infoStr{2}=sprintf('#points between red lines: %d/%d=%.2f',nx_99,ntotal,nx_99/ntotal);
infoStr{1}=sprintf('#total points: %d',ntotal);
text(b+delta,0,infoStr)

title(sprintf('a=%.2f b=%.2f c=%.2f; 99%% variation in [%.2f-%.2f %.2f+%.2f]',a,b,c,b,b-qlx,b,qux-b));
xlabel(sprintf('original %s',covName));
ylabel(sprintf('transformed %s',covName));


