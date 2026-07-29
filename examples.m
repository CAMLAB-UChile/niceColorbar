function examples
  % Learning path: QuickStart.m -> doc/GettingStarted.m -> examples (you are here)
  %
  % A detailed multi-figure walkthrough (styles, LaTeX titles, logos, per-line title
  % colors, theme overrides) showing the niceColorbar features.
  
  clc;
  close all;
  clearvars;

  %% figure 1: the simplest one with defaults; 
  %  theme mode follows the OS system color mode (dark or light)
  fig1 = figure(1);                                          % create a figure
  fig1.WindowStyle = "docked";                               % dock figure into a container
  contourf(peaks);                                           % make a plot
  xlabel("x");                                               % put the x-label
  ylabel("y");                                               % put the y-label
  nc1 = niceColorbar();                                      % instantiate a niceColorbar object
  nc1.colorbar();                                            % create the colorbar  

  %% figure 2: add colored title and logo; colorbar on right (default); 
  % theme mode is explicitly set to dark
  fig2 = figure(2);                                          % create a figure
  fig2.WindowStyle = "docked";                               % dock figure into a container
  contourf(peaks);                                           % make a plot
  xlabel("x","FontName","Arial","FontSize",12);              % put the x-label
  ylabel("y","FontName","Arial","FontSize",12);              % put the y-label
  nc7Sub2 = niceColorbar("modern.thin","paraview",12);           % instantiate a niceColorbar object
  nc7Sub2.Side = "bottom";                                       % set colorbar on bottom    
  nc7Sub2.NumColormapColors = 10;                                % set number of colormapcolors
  nc7Sub2.ThemeMode = "dark";                                    % set theme mode  
  nc7Sub2.TickLabelsFontName = "Segoe UI";                       % set tick labels font
  nc7Sub2.TickLabelsFormat = '%+.2f';                            % set tick label format    
  nc7Sub2.Title = {['(step = ',int2str(10),') $\sigma$']};       % format the title (LATEX);
  nc7Sub2.TitleColor = [0.50,0.65,0.98];                         % custom color for title                                                         
  nc7Sub2.Logo = ['\color[rgb]{0.3608,0.4,0.43529}NICE',...      % format the logo
              '\color[rgb]{0.8,0.251,0.2235}CLBR'];      
  nc7Sub2.LogoFontName = "Impact";                               % declare logo font name
  nc7Sub2.colorbar();                                            % create the colorbar

  %% figure 3: theme mode is explicitly set to dark; colorbar on top; 
  % colored title and logo
  fig3 = figure(3);                                          % create a figure
  fig3.WindowStyle = "docked";                               % dock figure into a container
  contourf(peaks);                                           % make a plot
  xlabel("x","FontName","Arial","FontSize",12);              % put the x-label
  ylabel("y","FontName","Arial","FontSize",12);              % put the y-label
  nc7Sub3 = niceColorbar("ultra.thin","fast",12);                % instantiate a niceColorbar object
  nc7Sub3.Side = "top";                                          % set colorbar on top
  nc7Sub3.NumColormapColors = 10;                                % set number of colormapcolors  
  nc7Sub3.TickLabelsFontName = "Segoe UI";                       % set tick labels font
  nc7Sub3.TickLabelsFormat = '%+.2f';                            % set tick label format    
  nc7Sub3.ThemeMode = "dark";                                    % set theme mode
  nc7Sub3.Title = {['\color[rgb]{0.28,0.57,0.87}(step = ',...    % format the title (TEX)
               int2str(10),'\color[rgb]{0.28,0.57,0.87})',...
               '\color[rgb]{0.95,0.67,0.03} u_{1,h}']};
  nc7Sub3.TitleInterpreter = "tex";                              % tex interpreter is essential
                                                             % if title is introduced in
                                                             % tex format
  nc7Sub3.Logo = ['\color[rgb]{0.3608,0.4,0.43529}NICE',...      % format the logo
              '\color[rgb]{0.8,0.251,0.2235}CLBR'];         
  nc7Sub3.LogoFontName = "Impact";                               % set logo font name
  nc7Sub3.colorbar();                                            % create the colorbar  

  %% figure 4: theme mode is explicitly set to light; colorbar on left;
  % colored title in LATEX format (default) and colored logo; 
  % capped colorbar limits
  fig4 = figure(4);                                          % create a figure
  fig4.WindowStyle = "docked";                               % dock figure into a container
  contourf(peaks);                                           % make a plot
  xlabel("x","FontName","Arial","FontSize",12);              % put the x-label
  ylabel("y","FontName","Arial","FontSize",12);              % put the y-label
  nc7Sub4 = niceColorbar("modern.thick","watermelon",12);        % instantiate a niceColorbar object
  nc7Sub4.Side = "left";                                         % set colorbar on left  
  nc7Sub4.NumColormapColors = 10;                                % set number of colormapcolors  
  nc7Sub4.TickLabelsFontName = "Segoe UI";                       % set tick labels font  
  nc7Sub4.ThemeMode = "light";                                   % set theme mode
  nc7Sub4.Title = {['(step = ',int2str(10),')'],...              % format the title (LATEX)
                '$\|\mathbf{u}\|$'};                         % first line auto-follows the theme color;
  nc7Sub4.TitleColor = {[],[0.17,0.61,0.39]};                    % custom color for the second line                                                              
  nc7Sub4.Logo = ['\color[rgb]{0.3608,0.4,0.43529}NICE',...      % format the logo
              '\color[rgb]{0.96,0.59,0.41}CLBR'];      
  nc7Sub4.LogoFontName = "Impact";                               % set logo font name
  nc7Sub4.colorbar();                                            % create the colorbar 
  nc7Sub4.setCappedLimits([-2.5 6.2])                            % set capped limits   

  %% figure 5: 3D plot; colored title and logo; theme mode is explicitly set to light
  fig5 = figure(5);                                          % create a figure
  fig5.WindowStyle = "docked";                               % dock figure into a container
  surf(peaks(50),"EdgeColor",[0.2,0.2,0.2]);                 % make a plot   
  view(3);                                                   % isometric view                            
  xlabel("x","FontName","Arial","FontSize",14);              % put the x-label
  ylabel("y","FontName","Arial","FontSize",14);              % put the y-label
  nc5 = niceColorbar("ultra","robot",16);                    % instantiate a niceColorbar object
  nc5.ThemeMode = "light";                                   % set theme mode  
  nc5.NumColormapColors = 12;                                % set number of colormapcolors
  nc5.TickLabelsFontName = "Segoe UI";                       % declare tick labels font   
  nc5.Title = {['(step = ',int2str(10),')'],...              % format the title (LATEX)
                '$\|\mathbf{u}\|$'};
  nc5.TitleColor = {[0.28,0.32,0.95],[0.36,0.40,0.44]};      % custom color for the title 
  nc5.Logo = ['\color[rgb]{0.3608,0.4,0.43529}NICE',...      % format the logo
              '\color[rgb]{0.8,0.251,0.2235}CLBR'];         
  nc5.LogoFontName = "Impact";                               % set logo font name
  nc5.colorbar();                                            % create the colorbar 

  %% figure 6: subplots (2d and 3d combined); colored title and logo; 
  % capped colorbar limits; colorbar on right, top, bottom, left;
  % theme mode explictly set to dark
  fig6 = figure(6);                                          % create a figure
  fig6.WindowStyle = "docked";                               % dock figure into a container

  ax1 = subplot(2,2,1);                                  % first axes
  contourf(peaks);                                       % make a plot                                        
  xlabel("x","FontName","Arial","FontSize",12);          % put the x-label
  ylabel("y","FontName","Arial","FontSize",12);          % put the y-label
  nc7Sub1 = niceColorbar("ultra.thin","polar",8);        % instantiate a niceColorbar object
  nc7Sub1.ThemeMode = "dark";                            % set theme mode
  nc7Sub1.TickLabelsFontName = "Segoe UI";               % set tick labels font 
  nc7Sub1.TickLabelsFontSize = 8;                        % set tick labels font size   
  nc7Sub1.Title = {'$\xi$'};                             % format the title (LATEX)
  nc7Sub1.TitleFontSize = 20;                            % set title font size
  nc7Sub1.Logo = ['\color[rgb]{0.3608,0.4,0.43529}NICE',...
                  '\color[rgb]{0.8,0.251,0.2235}CLBR'];  % format the logo
  nc7Sub1.LogoFontName = "Impact";                       % set logo font name  
  axes(ax1);                                             % make ax1 to be the current axes
  nc7Sub1.colorbar();                                    % create the colorbar   
  nc7Sub1.setCappedLimits([-4.2 5.6])                    % set capped limits   

  ax2 = subplot(2,2,2);                                  % second axes
  contourf(peaks(50));                                   % make a plot 
  xlabel("x","FontName","Arial","FontSize",12);          % put the x-label
  ylabel("y","FontName","Arial","FontSize",12);          % put the y-label
  nc7Sub2 = niceColorbar("modern","nice",10);            % instantiate a niceColorbar object
  nc7Sub2.ThemeMode = "dark";                            % set theme mode  
  nc7Sub2.TickLabelsFontName = "Segoe UI";               % declare tick labels font    
  nc7Sub2.TickLabelsFontSize = 8;                        % set tick labels font size    
  nc7Sub2.TickLabelsFormat = '%+.2f';                    % set tick label format  
  nc7Sub2.Side = "top";                                  % set colorbar on top  
  nc7Sub2.Title = {'$\eta$'};                            % format the title (LATEX)
  nc7Sub2.TitleFontSize = 20;                            % set title font size  
  nc7Sub2.Logo = ['\color[rgb]{0.3608,0.4,0.43529}NICE',...  
                  '\color[rgb]{0.8,0.251,0.2235}CLBR'];  % format the logo
  nc7Sub2.LogoFontName = "Impact";                       % set logo font name    
  axes(ax2);                                             % make ax2 to be the current axes  
  nc7Sub2.colorbar();                                        % create the colorbar    

  ax3 = subplot(2,2,3);                                  % third axes
  surf(peaks(30),"EdgeColor",[0.2,0.2,0.2]);             % create a plot 
  view(3);                                               % isometric view                            
  xlabel("x","FontName","Arial","FontSize",12);          % put the x-label
  ylabel("y","FontName","Arial","FontSize",12);          % put the y-label
  zlabel("$\psi$","FontName","Arial","FontSize",12,...   % put the z-label 
         "Interpreter","latex");        
  nc7Sub3 = niceColorbar("modern.thin","ultra",14);      % instantiate a niceColorbar object
  nc7Sub3.Side = "bottom";                               % set colorbar on left    
  nc7Sub3.ThemeMode = "dark";                            % set theme mode   
  nc7Sub3.TickLabelsFontName = "Segoe UI";               % declare tick labels font   
  nc7Sub3.TickLabelsFontSize = 8;                        % set tick labels font size     
  nc7Sub3.TickLabelsFormat = '%+.2f';                    % set tick label format
  nc7Sub3.Title = {'$\psi$'};                            % format the title
  nc7Sub3.TitleFontSize = 20;                            % set title font size  
  nc7Sub3.TitleColor = {[0.50,0.65,0.98]};               % custom color for title 
  nc7Sub3.Logo = ['\color[rgb]{0.3608,0.4,0.43529}NICE',...  
                  '\color[rgb]{0.8,0.251,0.2235}CLBR'];  % format the logo
  nc7Sub3.LogoFontName = "Impact";                       % set logo font name     
  nc7Sub3.LogoFontSize = 18;                             % set logo font size 
  axes(ax3);                                             % make ax3 to be the current axes   
  nc7Sub3.colorbar();                                        % create the colorbar   

  ax4 = subplot(2,2,4);                                  % fourth axes
  contourf(peaks(40));                                   % make a plot 
  xlabel("x","FontName","Arial","FontSize",12);          % put the x-label
  ylabel("y","FontName","Arial","FontSize",12);          % put the y-label
  nc7Sub4 = niceColorbar("ultra","cork",8);              % instantiate a niceColorbar object
  nc7Sub4.ThemeMode = "dark";                            % set theme mode  
  nc7Sub4.TickLabelsFontName = "Segoe UI";               % declare tick labels font    
  nc7Sub4.TickLabelsFontSize = 8;                        % set tick labels font size     
  nc7Sub4.Side = "left";                                 % set colorbar on left  
  nc7Sub4.Title = {['(step = ',int2str(10),')'],...      % format the title
    '$\|\mathbf{u}\|$'};
  nc7Sub4.TitleColor = {[0.28,0.57,0.87],...
                        [0.17,0.61,0.39]};               % custom color for title 
  nc7Sub4.TitleFontSize = 16;                            % set title font size   
  nc7Sub4.Logo = ['\color[rgb]{0.3608,0.4,0.43529}NICE',...  
                  '\color[rgb]{0.8,0.251,0.2235}CLBR'];  % format the logo
  nc7Sub4.LogoFontName = "Impact";                       % set logo font name 
  axes(ax4);                                             % make ax4 to be the current axes    
  nc7Sub4.colorbar();                                    % create the colorbar 
  nc7Sub4.setCappedLimits([-4.2 5.6])                    % set capped limits      

  %% figure 7: subplots (2d and 3d combined); colored title and logo; 
  % capped colorbar limits; colorbar on right, top, bottom, left;
  % theme mode explictly set to light
  fig7 = figure(7);                                      % create a figure
  fig7.WindowStyle = "docked";                           % dock figure into a container

  ax1 = subplot(2,2,1);                                  % first axes
  contourf(peaks);                                       % make a plot                                        
  xlabel("x","FontName","Arial","FontSize",12);          % put the x-label
  ylabel("y","FontName","Arial","FontSize",12);          % put the y-label
  nc7Sub1 = niceColorbar("ultra.thin","polar",8);        % instantiate a niceColorbar object
  nc7Sub1.ThemeMode = "light";                           % set theme mode
  nc7Sub1.TickLabelsFontName = "Segoe UI";               % set tick labels font 
  nc7Sub1.TickLabelsFontSize = 8;                        % set tick labels font size   
  nc7Sub1.Title = {'$\xi$'};                             % format the title (LATEX)
  nc7Sub1.TitleFontSize = 20;                            % set title font size
  nc7Sub1.Logo = ['\color[rgb]{0.3608,0.4,0.43529}NICE',...
                  '\color[rgb]{0.8,0.251,0.2235}CLBR'];  % format the logo
  nc7Sub1.LogoFontName = "Impact";                       % set logo font name  
  axes(ax1);                                             % make ax1 to be the current axes
  nc7Sub1.colorbar();                                    % create the colorbar   
  nc7Sub1.setCappedLimits([-4.2 5.6])                    % set capped limits   

  ax2 = subplot(2,2,2);                                  % second axes
  contourf(peaks(50));                                   % make a plot 
  xlabel("x","FontName","Arial","FontSize",12);          % put the x-label
  ylabel("y","FontName","Arial","FontSize",12);          % put the y-label
  nc7Sub2 = niceColorbar("modern","nice",10);            % instantiate a niceColorbar object
  nc7Sub2.ThemeMode = "light";                           % set theme mode  
  nc7Sub2.TickLabelsFontName = "Segoe UI";               % declare tick labels font    
  nc7Sub2.TickLabelsFontSize = 8;                        % set tick labels font size    
  nc7Sub2.TickLabelsFormat = '%+.2f';                    % set tick label format  
  nc7Sub2.Side = "top";                                  % set colorbar on top  
  nc7Sub2.Title = {'$\eta$'};                            % format the title (LATEX)
  nc7Sub2.TitleFontSize = 20;                            % set title font size  
  nc7Sub2.Logo = ['\color[rgb]{0.3608,0.4,0.43529}NICE',...  
                  '\color[rgb]{0.8,0.251,0.2235}CLBR'];  % format the logo
  nc7Sub2.LogoFontName = "Impact";                       % set logo font name    
  axes(ax2);                                             % make ax2 to be the current axes  
  nc7Sub2.colorbar();                                        % create the colorbar    

  ax3 = subplot(2,2,3);                                  % third axes
  surf(peaks(30),"EdgeColor",[0.2,0.2,0.2]);             % create a plot 
  view(3);                                               % isometric view                            
  xlabel("x","FontName","Arial","FontSize",12);          % put the x-label
  ylabel("y","FontName","Arial","FontSize",12);          % put the y-label
  zlabel("$\psi$","FontName","Arial","FontSize",12,...   % put the z-label 
         "Interpreter","latex");        
  nc7Sub3 = niceColorbar("modern.thin","ultra",14);      % instantiate a niceColorbar object
  nc7Sub3.Side = "bottom";                               % set colorbar on left    
  nc7Sub3.ThemeMode = "light";                           % set theme mode   
  nc7Sub3.TickLabelsFontName = "Segoe UI";               % declare tick labels font   
  nc7Sub3.TickLabelsFontSize = 8;                        % set tick labels font size     
  nc7Sub3.TickLabelsFormat = '%+.2f';                    % set tick label format
  nc7Sub3.Title = {'$\psi$'};                            % format the title
  nc7Sub3.TitleFontSize = 20;                            % set title font size  
  nc7Sub3.TitleColor = {[0.50,0.65,0.98]};               % custom color for title 
  nc7Sub3.Logo = ['\color[rgb]{0.3608,0.4,0.43529}NICE',...  
                  '\color[rgb]{0.8,0.251,0.2235}CLBR'];  % format the logo
  nc7Sub3.LogoFontName = "Impact";                       % set logo font name     
  nc7Sub3.LogoFontSize = 18;                             % set logo font size 
  axes(ax3);                                             % make ax3 to be the current axes   
  nc7Sub3.colorbar();                                        % create the colorbar   

  ax4 = subplot(2,2,4);                                  % fourth axes
  contourf(peaks(40));                                   % make a plot 
  xlabel("x","FontName","Arial","FontSize",12);          % put the x-label
  ylabel("y","FontName","Arial","FontSize",12);          % put the y-label
  nc7Sub4 = niceColorbar("ultra","cork",8);              % instantiate a niceColorbar object
  nc7Sub4.ThemeMode = "light";                           % set theme mode  
  nc7Sub4.TickLabelsFontName = "Segoe UI";               % declare tick labels font    
  nc7Sub4.TickLabelsFontSize = 8;                        % set tick labels font size     
  nc7Sub4.Side = "left";                                 % set colorbar on left  
  nc7Sub4.Title = {['(step = ',int2str(10),')'],...      % format the title
                    '$\|\mathbf{u}\|$'};
  nc7Sub4.TitleColor = {[0.28,0.57,0.87],...
                        [0.17,0.61,0.39]};               % custom color for title 
  nc7Sub4.TitleFontSize = 16;                            % set title font size   
  nc7Sub4.Logo = ['\color[rgb]{0.3608,0.4,0.43529}NICE',...  
                  '\color[rgb]{0.8,0.251,0.2235}CLBR'];  % format the logo
  nc7Sub4.LogoFontName = "Impact";                       % set logo font name 
  axes(ax4);                                             % make ax4 to be the current axes    
  nc7Sub4.colorbar();                                    % create the colorbar 
  nc7Sub4.setCappedLimits([-4.2 5.6])                    % set capped limits      

  %% figure 8: Autoscaled colorbar tick labels formatted in scientific notation with common 
  %  exponent to all tick labels

  % create a figure with a plot
  fig8 = figure(8);                                      % create a figure
  fig8.WindowStyle = "docked";                           % dock figures into one container
  [X,Y] = meshgrid(-5:.5:5);
  Z = Y.*sin(X) - X.*cos(Y) + 5000;
  surf(X,Y,Z,'FaceAlpha',0.8)  
  view(3);                                               % isometric view
  xlabel("x","FontName","Arial","FontSize",16);          % put x-label
  ylabel("y","FontName","Arial","FontSize",16);          % put y-label   
  zlabel("$\|\mathbf{u}\|$","FontName","Arial",...
         "FontSize",18,"Interpreter","latex");           % put z-label  
  nc8 = niceColorbar("modern","nice",12);                % instantiate a niceColorbar object
  nc8.ThemeMode = "dark";                                % theme mode    
  nc8.TickLabelsFontName = "Segoe UI";                   % declare tick labels font    
  nc8.Title = {['(step = ',int2str(10),')'],...          % set title
                '$\|\mathbf{u}\|$'};                            
  nc8.Logo = ['\color[rgb]{0.360784,0.4,0.435294}NICE',...
              '\color[rgb]{0.85,0.0,0.0}CLBR'];          % put a logo
  nc8.LogoFontName = "Impact";                           % declare logo font name 
  nc8.colorbar();                                        % create the colorbar   
  nc8.TickLabelsAutoScale = true;                        % autoscale tick labels and use 
                                                         % scientific notation with common 
                                                         % exponent to all tick labels
  nc8.TickLabelsAutoScaleDecimals = 2;                   % number of digits for tick labels
                                                         % (TickLabelsFormat is ignored while
                                                         % TickLabelsAutoScale is true)

  % save figure: called with no folder argument (as here), all
  % three methods write into a "SavedFigures" folder inside the
  % niceColorbar toolbox folder - NICE is the script-mode behavior. Calling
  % the same methods from niceColorbar.session() instead pops up a
  % folder-picker dialog (uigetdir) and saves wherever the user selects.
  % saveAsFIG() writes an editable .fig file (re-openable in MATLAB with
  % the colorbar and all its styling intact), unlike the PNG/PDF exports.
  nc8.saveAsPNG();                                       % save figure as PNG image
  nc8.saveAsPDF();                                       % print figure to a PDF file
  nc8.saveAsFIG();                                       % save as MATLAB figure  

end
