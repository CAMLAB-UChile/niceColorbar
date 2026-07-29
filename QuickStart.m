function QuickStart
  % Learning path: QuickStart (you are here) -> doc/GettingStarted.m -> examples.m
  %
  % Quick example to introduce the niceColorbar features. See
  % doc/GettingStarted.m next for a guided tour of the available commands
  % and options, then examples.m for a multi-figure walkthrough (styles,
  % LaTeX titles, logos, per-line title colors, theme overrides).

  clc;
  close all;
  clearvars;

  % 1: create a plot
  contourf(peaks);    
  xlabel("x","FontName","Arial","FontSize",18);           % put x-label
  ylabel("y","FontName","Arial","FontSize",18);           % put y-label    

  % 2: Initial colorbar with title
  nc = niceColorbar('modern.thick', 'autumn', 10);        % instantiate a niceColorbar object
  nc.ThemeMode = "light";                                 % set theme mode  
  nc.Title = {'My title'};                                % set title
  nc.Side = "top";                                        % colorbar location  
  nc.colorbar();                                          % create colorbar 
  nc.saveAsPNG();                                         % save figure as PNG image
  nc.saveAsPDF();                                         % print figure to a PDF file
  nc.saveAsFIG();                                         % save as MATLAB figure  
  
  % 3: Update colorbar (properties auto-refresh the live colorbar - no rebuild needed)
  nc.Style = "ultra.thin";                                % update colorbar style
  nc.Title = {'Updated','Title'};                         % update title
  nc.TitleColor = {[0.28,0.32,0.95],[0.17,0.61,0.39]};    % custom color for updated title
  nc.ColormapName = 'cool';                               % update colormap
  nc.ThemeMode = "dark";                                  % update theme mode   
  nc.TickLabelsFontName = "Segoe UI";                     % update tick labels font 
  nc.TickLabelsFontSize = 12;                             % update tick labels font size   
  nc.Side = "left";                                       % update colorbar location   
  nc.TickLabelsFormat = '%+.2f';                          % update tick label format  
  nc.Logo = ['\color[rgb]{0.3608,0.4,0.43529}NICE',...    % put a logo
             '\color[rgb]{0.9,0.11,1.0}CLBR'];   
  nc.LogoFontName = "Impact";                             % set logo font name  
  nc.saveAsPNG();                                         % save figure as PNG image
  nc.saveAsPDF();                                         % print figure to a PDF file
  nc.saveAsFIG();                                         % save as MATLAB figure  
  
end