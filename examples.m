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
  contourf(100*peaks);                                       % make a plot
  xlabel("x","FontName","Arial","FontSize",12);              % put the x-label
  ylabel("y","FontName","Arial","FontSize",12);              % put the y-label
  nc2 = niceColorbar("modern.thin","paraview",12);           % instantiate a niceColorbar object
  nc2.Side = "bottom";                                       % set colorbar on bottom    
  nc2.NumColormapColors = 10;                                % set number of colormapcolors
  nc2.ThemeMode = "dark";                                    % set theme mode  
  nc2.TickLabelsFontName = "Segoe UI";                       % set tick labels font
  nc2.TickLabelsFormat = '%+.2f';                            % set tick label format    
  nc2.Title = {['(step = ',int2str(10),') $\sigma$']};       % format the title (LATEX);
  nc2.TitleColor = [0.50,0.65,0.98];                         % custom color for title                                                         
  nc2.Logo = ['\color[rgb]{0.3608,0.4,0.43529}NICE',...      % format the logo
              '\color[rgb]{0.8,0.251,0.2235}CLBR'];      
  nc2.LogoFontName = "Impact";                               % declare logo font name
  nc2.colorbar();                                            % create the colorbar

  %% figure 3: theme mode is explicitly set to dark; colorbar on top; 
  % colored title and logo
  fig3 = figure(3);                                          % create a figure
  fig3.WindowStyle = "docked";                               % dock figure into a container
  contourf(peaks);                                           % make a plot
  xlabel("x","FontName","Arial","FontSize",12);              % put the x-label
  ylabel("y","FontName","Arial","FontSize",12);              % put the y-label
  nc3 = niceColorbar("ultra.thin","fast",12);                % instantiate a niceColorbar object
  nc3.Side = "top";                                          % set colorbar on top
  nc3.NumColormapColors = 10;                                % set number of colormapcolors  
  nc3.TickLabelsFontName = "Segoe UI";                       % set tick labels font
  nc3.TickLabelsFormat = '%+.2f';                            % set tick label format    
  nc3.ThemeMode = "dark";                                    % set theme mode
  nc3.Title = {['\color[rgb]{0.28,0.57,0.87}(step = ',...    % format the title (TEX)
               int2str(10),'\color[rgb]{0.28,0.57,0.87})',...
               '\color[rgb]{0.95,0.67,0.03} u_{1,h}']};
  nc3.TitleInterpreter = "tex";                              % tex interpreter is essential
                                                             % if title is introduced in
                                                             % tex format
  nc3.Logo = ['\color[rgb]{0.3608,0.4,0.43529}NICE',...      % format the logo
              '\color[rgb]{0.8,0.251,0.2235}CLBR'];         
  nc3.LogoFontName = "Impact";                               % set logo font name
  nc3.colorbar();                                            % create the colorbar  

  %% figure 4: theme mode is explicitly set to light; colorbar on left;
  % colored title in LATEX format (default) and colored logo; 
  % capped colorbar limits
  fig4 = figure(4);                                              % create a figure
  fig4.WindowStyle = "docked";                                   % dock figure into a container
  contourf(100*peaks);                                           % make a plot
  xlabel("x","FontName","Arial","FontSize",12);                  % put the x-label
  ylabel("y","FontName","Arial","FontSize",12);                  % put the y-label
  nc4 = niceColorbar("modern.thick","watermelon",12);        % instantiate a niceColorbar object
  nc4.Side = "left";                                         % set colorbar on left  
  nc4.NumColormapColors = 10;                                % set number of colormapcolors  
  nc4.TickLabelsFontName = "Segoe UI";                       % set tick labels font  
  nc4.ThemeMode = "light";                                   % set theme mode
  nc4.Title = {['(step = ',int2str(10),')'],...              % format the title (LATEX)
                '$\|\mathbf{u}\|$'};                             % first line auto-follows the theme color;
  nc4.TitleColor = {[],[0.17,0.61,0.39]};                    % custom color for the second line                                                              
  nc4.Logo = ['\color[rgb]{0.3608,0.4,0.43529}NICE',...      % format the logo
              '\color[rgb]{0.96,0.59,0.41}CLBR'];      
  nc4.LogoFontName = "Impact";                               % set logo font name
  nc4.colorbar();                                            % create the colorbar 
  nc4.setCappedLimits([-250 620])                            % set capped limits   
  nc4.TickLabelsAutoScale = true;                            % autoscale tick labels and use
                                                                 % scientific notation with a common
                                                                 % exponent across all tick labels
  nc4.TickLabelsAutoScaleDecimals = 2;                       % number of decimal digits shown
                                                                 % (TickLabelsFormat is ignored while
                                                                 % TickLabelsAutoScale is true)  

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

  ax6sub1 = subplot(2,2,1);                                  % first axes
  contourf(100*peaks);                                       % make a plot                                        
  xlabel("x","FontName","Arial","FontSize",12);          % put the x-label
  ylabel("y","FontName","Arial","FontSize",12);          % put the y-label
  nc6sub1 = niceColorbar("ultra.thin","polar",8);        % instantiate a niceColorbar object
  nc6sub1.ThemeMode = "dark";                            % set theme mode
  nc6sub1.TickLabelsFontName = "Segoe UI";               % set tick labels font 
  nc6sub1.TickLabelsFontSize = 8;                        % set tick labels font size   
  nc6sub1.Title = {'$\xi$'};                             % format the title (LATEX)
  nc6sub1.TitleFontSize = 20;                            % set title font size
  nc6sub1.Logo = ['\color[rgb]{0.3608,0.4,0.43529}NICE',...
                  '\color[rgb]{0.8,0.251,0.2235}CLBR'];  % format the logo
  nc6sub1.LogoFontName = "Impact";                       % set logo font name  
  axes(ax6sub1);                                             % make ax1 to be the current axes
  nc6sub1.colorbar();                                    % create the colorbar   
  nc6sub1.setCappedLimits([-420 560])                    % set capped limits
  nc6sub1.TickLabelsAutoScale = true;                    % autoscale tick labels and use
                                                         % scientific notation with a common
                                                         % exponent across all tick labels
  nc6sub1.TickLabelsAutoScaleDecimals = 2;               % number of decimal digits shown
                                                         % (TickLabelsFormat is ignored while
                                                         % TickLabelsAutoScale is true)

  ax6sub2 = subplot(2,2,2);                                  % second axes
  contourf(peaks(50));                                   % make a plot 
  xlabel("x","FontName","Arial","FontSize",12);          % put the x-label
  ylabel("y","FontName","Arial","FontSize",12);          % put the y-label
  nc6Sub2 = niceColorbar("modern","nice",10);            % instantiate a niceColorbar object
  nc6Sub2.ThemeMode = "dark";                            % set theme mode  
  nc6Sub2.TickLabelsFontName = "Segoe UI";               % declare tick labels font    
  nc6Sub2.TickLabelsFontSize = 8;                        % set tick labels font size    
  nc6Sub2.TickLabelsFormat = '%+.2f';                    % set tick label format  
  nc6Sub2.Side = "top";                                  % set colorbar on top  
  nc6Sub2.Title = {'$\eta$'};                            % format the title (LATEX)
  nc6Sub2.TitleFontSize = 20;                            % set title font size  
  nc6Sub2.Logo = ['\color[rgb]{0.3608,0.4,0.43529}NICE',...  
                  '\color[rgb]{0.8,0.251,0.2235}CLBR'];  % format the logo
  nc6Sub2.LogoFontName = "Impact";                       % set logo font name    
  axes(ax6sub2);                                             % make ax2 to be the current axes  
  nc6Sub2.colorbar();                                        % create the colorbar    

  ax6sub3 = subplot(2,2,3);                                  % third axes
  surf(peaks(30),"EdgeColor",[0.2,0.2,0.2]);             % create a plot 
  view(3);                                               % isometric view                            
  xlabel("x","FontName","Arial","FontSize",12);          % put the x-label
  ylabel("y","FontName","Arial","FontSize",12);          % put the y-label
  zlabel("$\psi$","FontName","Arial","FontSize",12,...   % put the z-label 
         "Interpreter","latex");        
  nc6Sub3 = niceColorbar("modern.thin","ultra",14);      % instantiate a niceColorbar object
  nc6Sub3.Side = "bottom";                               % set colorbar on left    
  nc6Sub3.ThemeMode = "dark";                            % set theme mode   
  nc6Sub3.TickLabelsFontName = "Segoe UI";               % declare tick labels font   
  nc6Sub3.TickLabelsFontSize = 8;                        % set tick labels font size     
  nc6Sub3.TickLabelsFormat = '%+.2f';                    % set tick label format
  nc6Sub3.Title = {'$\psi$'};                            % format the title
  nc6Sub3.TitleFontSize = 20;                            % set title font size  
  nc6Sub3.TitleColor = {[0.50,0.65,0.98]};               % custom color for title 
  nc6Sub3.Logo = ['\color[rgb]{0.3608,0.4,0.43529}NICE',...  
                  '\color[rgb]{0.8,0.251,0.2235}CLBR'];  % format the logo
  nc6Sub3.LogoFontName = "Impact";                       % set logo font name     
  nc6Sub3.LogoFontSize = 18;                             % set logo font size 
  axes(ax6sub3);                                             % make ax3 to be the current axes   
  nc6Sub3.colorbar();                                        % create the colorbar   

  ax6sub4 = subplot(2,2,4);                                  % fourth axes
  contourf(peaks(40));                                   % make a plot 
  xlabel("x","FontName","Arial","FontSize",12);          % put the x-label
  ylabel("y","FontName","Arial","FontSize",12);          % put the y-label
  nc6Sub4 = niceColorbar("ultra","cork",8);              % instantiate a niceColorbar object
  nc6Sub4.ThemeMode = "dark";                            % set theme mode  
  nc6Sub4.TickLabelsFontName = "Segoe UI";               % declare tick labels font    
  nc6Sub4.TickLabelsFontSize = 8;                        % set tick labels font size     
  nc6Sub4.Side = "left";                                 % set colorbar on left  
  nc6Sub4.Title = {['(step = ',int2str(10),')'],...      % format the title
    '$\|\mathbf{u}\|$'};
  nc6Sub4.TitleColor = {[0.28,0.57,0.87],...
                        [0.17,0.61,0.39]};               % custom color for title 
  nc6Sub4.TitleFontSize = 16;                            % set title font size   
  nc6Sub4.Logo = ['\color[rgb]{0.3608,0.4,0.43529}NICE',...  
                  '\color[rgb]{0.8,0.251,0.2235}CLBR'];  % format the logo
  nc6Sub4.LogoFontName = "Impact";                       % set logo font name 
  axes(ax6sub4);                                             % make ax4 to be the current axes    
  nc6Sub4.colorbar();                                    % create the colorbar 
  nc6Sub4.setCappedLimits([-4.2 5.6])                    % set capped limits      

  %% figure 7: subplots (2d and 3d combined); colored title and logo; 
  % capped colorbar limits; colorbar on right, top, bottom, left;
  % theme mode explictly set to light
  fig7 = figure(7);                                      % create a figure
  fig7.WindowStyle = "docked";                           % dock figure into a container

  ax7sub1 = subplot(2,2,1);                                  % first axes
  contourf(100*peaks);                                       % make a plot                                        
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
  axes(ax7sub1);                                             % make ax1 to be the current axes
  nc7Sub1.colorbar();                                    % create the colorbar   
  nc7Sub1.setCappedLimits([-420 560])                    % set capped limits
  nc7Sub1.TickLabelsAutoScale = true;                    % autoscale tick labels and use
                                                         % scientific notation with a common
                                                         % exponent across all tick labels
  nc7Sub1.TickLabelsAutoScaleDecimals = 2;               % number of decimal digits shown
                                                         % (TickLabelsFormat is ignored while
                                                         % TickLabelsAutoScale is true) 

  ax7sub2 = subplot(2,2,2);                                  % second axes
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
  axes(ax7sub2);                                             % make ax2 to be the current axes  
  nc7Sub2.colorbar();                                        % create the colorbar    

  ax7sub3 = subplot(2,2,3);                                  % third axes
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
  axes(ax7sub3);                                             % make ax3 to be the current axes   
  nc7Sub3.colorbar();                                        % create the colorbar   

  ax7sub4 = subplot(2,2,4);                                  % fourth axes
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
  axes(ax7sub4);                                             % make ax4 to be the current axes    
  nc7Sub4.colorbar();                                    % create the colorbar 
  nc7Sub4.setCappedLimits([-4.2 5.6])                    % set capped limits  

  %% figure 8: subplots (2d and 3d combined); colored title and logo; 
  % capped colorbar limits; colorbar on right, top, bottom, left;
  % theme mode explictly set to cobalt
  fig8 = figure(8);                                      % create a figure
  fig8.WindowStyle = "docked";                           % dock figure into a container

  ax8sub1 = subplot(2,2,1);                                  % first axes
  contourf(100*peaks);                                       % make a plot                                        
  xlabel("x","FontName","Arial","FontSize",12);          % put the x-label
  ylabel("y","FontName","Arial","FontSize",12);          % put the y-label
  nc8Sub1 = niceColorbar("ultra.thin","polar",8);        % instantiate a niceColorbar object
  nc8Sub1.ThemeMode = "cobalt";                          % set theme mode
  nc8Sub1.TickLabelsFontName = "Segoe UI";               % set tick labels font 
  nc8Sub1.TickLabelsFontSize = 8;                        % set tick labels font size   
  nc8Sub1.Title = {'$\xi$'};                             % format the title (LATEX)
  nc8Sub1.TitleFontSize = 20;                            % set title font size
  nc8Sub1.Logo = ['\color[rgb]{0.3608,0.4,0.43529}NICE',...
                  '\color[rgb]{0.8,0.251,0.2235}CLBR'];  % format the logo
  nc8Sub1.LogoFontName = "Impact";                       % set logo font name  
  axes(ax8sub1);                                             % make ax1 to be the current axes
  nc8Sub1.colorbar();                                    % create the colorbar   
  nc8Sub1.setCappedLimits([-420 560])                    % set capped limits
  nc8Sub1.TickLabelsAutoScale = true;                    % autoscale tick labels and use
                                                         % scientific notation with a common
                                                         % exponent across all tick labels
  nc8Sub1.TickLabelsAutoScaleDecimals = 2;               % number of decimal digits shown
                                                         % (TickLabelsFormat is ignored while
                                                         % TickLabelsAutoScale is true)  

  ax8sub2 = subplot(2,2,2);                                  % second axes
  contourf(peaks(50));                                   % make a plot 
  xlabel("x","FontName","Arial","FontSize",12);          % put the x-label
  ylabel("y","FontName","Arial","FontSize",12);          % put the y-label
  nc8Sub2 = niceColorbar("modern","nice",10);            % instantiate a niceColorbar object
  nc8Sub2.ThemeMode = "cobalt";                          % set theme mode  
  nc8Sub2.TickLabelsFontName = "Segoe UI";               % declare tick labels font    
  nc8Sub2.TickLabelsFontSize = 8;                        % set tick labels font size    
  nc8Sub2.TickLabelsFormat = '%+.2f';                    % set tick label format  
  nc8Sub2.Side = "top";                                  % set colorbar on top  
  nc8Sub2.Title = {'$\eta$'};                            % format the title (LATEX)
  nc8Sub2.TitleFontSize = 20;                            % set title font size  
  nc8Sub2.Logo = ['\color[rgb]{0.3608,0.4,0.43529}NICE',...  
                  '\color[rgb]{0.8,0.251,0.2235}CLBR'];  % format the logo
  nc8Sub2.LogoFontName = "Impact";                       % set logo font name    
  axes(ax8sub2);                                             % make ax2 to be the current axes  
  nc8Sub2.colorbar();                                        % create the colorbar    

  ax8sub3 = subplot(2,2,3);                                  % third axes
  surf(peaks(30),"EdgeColor",[0.2,0.2,0.2]);             % create a plot 
  view(3);                                               % isometric view                            
  xlabel("x","FontName","Arial","FontSize",12);          % put the x-label
  ylabel("y","FontName","Arial","FontSize",12);          % put the y-label
  zlabel("$\psi$","FontName","Arial","FontSize",12,...   % put the z-label 
         "Interpreter","latex");        
  nc8Sub3 = niceColorbar("modern.thin","ultra",14);      % instantiate a niceColorbar object
  nc8Sub3.Side = "bottom";                               % set colorbar on left    
  nc8Sub3.ThemeMode = "cobalt";                          % set theme mode   
  nc8Sub3.TickLabelsFontName = "Segoe UI";               % declare tick labels font   
  nc8Sub3.TickLabelsFontSize = 8;                        % set tick labels font size     
  nc8Sub3.TickLabelsFormat = '%+.2f';                    % set tick label format
  nc8Sub3.Title = {'$\psi$'};                            % format the title
  nc8Sub3.TitleFontSize = 20;                            % set title font size  
  nc8Sub3.TitleColor = {[0.50,0.65,0.98]};               % custom color for title 
  nc8Sub3.Logo = ['\color[rgb]{0.3608,0.4,0.43529}NICE',...  
                  '\color[rgb]{0.8,0.251,0.2235}CLBR'];  % format the logo
  nc8Sub3.LogoFontName = "Impact";                       % set logo font name     
  nc8Sub3.LogoFontSize = 18;                             % set logo font size 
  axes(ax8sub3);                                             % make ax3 to be the current axes   
  nc8Sub3.colorbar();                                        % create the colorbar   

  ax8sub4 = subplot(2,2,4);                                  % fourth axes
  contourf(peaks(40));                                   % make a plot 
  xlabel("x","FontName","Arial","FontSize",12);          % put the x-label
  ylabel("y","FontName","Arial","FontSize",12);          % put the y-label
  nc8Sub4 = niceColorbar("ultra","cork",8);              % instantiate a niceColorbar object
  nc8Sub4.ThemeMode = "cobalt";                           % set theme mode  
  nc8Sub4.TickLabelsFontName = "Segoe UI";               % declare tick labels font    
  nc8Sub4.TickLabelsFontSize = 8;                        % set tick labels font size     
  nc8Sub4.Side = "left";                                 % set colorbar on left  
  nc8Sub4.Title = {['(step = ',int2str(10),')'],...      % format the title
                    '$\|\mathbf{u}\|$'};
  nc8Sub4.TitleColor = {[0.28,0.57,0.87],...
                        [0.17,0.61,0.39]};               % custom color for title 
  nc8Sub4.TitleFontSize = 16;                            % set title font size   
  nc8Sub4.Logo = ['\color[rgb]{0.3608,0.4,0.43529}NICE',...  
                  '\color[rgb]{0.8,0.251,0.2235}CLBR'];  % format the logo
  nc8Sub4.LogoFontName = "Impact";                       % set logo font name 
  axes(ax8sub4);                                             % make ax4 to be the current axes    
  nc8Sub4.colorbar();                                    % create the colorbar 
  nc8Sub4.setCappedLimits([-4.2 5.6])                    % set capped limits    

  %% figure 9: Autoscaled colorbar tick labels formatted in scientific notation with common 
  %  exponent to all tick labels

  % create a figure with a plot
  fig9 = figure(9);                                      % create a figure
  fig9.WindowStyle = "docked";                           % dock figures into one container
  [X,Y] = meshgrid(-5:.5:5);
  Z = Y.*sin(X) - X.*cos(Y) + 5000;
  surf(X,Y,Z,'FaceAlpha',0.8)  
  view(3);                                               % isometric view
  xlabel("x","FontName","Arial","FontSize",16);          % put x-label
  ylabel("y","FontName","Arial","FontSize",16);          % put y-label   
  zlabel("$\|\mathbf{u}\|$","FontName","Arial",...
         "FontSize",18,"Interpreter","latex");           % put z-label  
  nc9 = niceColorbar("modern","nice",12);                % instantiate a niceColorbar object
  nc9.ThemeMode = "dark";                                % theme mode    
  nc9.TickLabelsFontName = "Segoe UI";                   % declare tick labels font    
  nc9.Title = {['(step = ',int2str(10),')'],...          % set title
                '$\|\mathbf{u}\|$'};                            
  nc9.Logo = ['\color[rgb]{0.360784,0.4,0.435294}NICE',...
              '\color[rgb]{0.85,0.0,0.0}CLBR'];          % put a logo
  nc9.LogoFontName = "Impact";                           % declare logo font name 
  nc9.colorbar();                                        % create the colorbar   
  nc9.TickLabelsAutoScale = true;                        % autoscale tick labels and use 
                                                         % scientific notation with common 
                                                         % exponent to all tick labels
  nc9.TickLabelsAutoScaleDecimals = 2;                   % number of digits for tick labels
                                                         % (TickLabelsFormat is ignored while
                                                         % TickLabelsAutoScale is true)

  % save figure: called with no folder argument (as here), all
  % three methods write into a "SavedFigures" folder inside the
  % niceColorbar toolbox folder - NICE is the script-mode behavior. Calling
  % the same methods from niceColorbar.session() instead pops up a
  % folder-picker dialog (uigetdir) and saves wherever the user selects.
  % saveAsFIG() writes an editable .fig file (re-openable in MATLAB with
  % the colorbar and all its styling intact), unlike the PNG/PDF exports.
  nc9.saveAsPNG();                                       % save figure as PNG image
  nc9.saveAsPDF();                                       % print figure to a PDF file
  nc9.saveAsFIG();                                       % save as MATLAB figure  

  %% figure 10: Autoscaled colorbar tick labels formatted in scientific notation with common 
  %  exponent to all tick labels. ThemeMode explicitly set to cobalt.

  % create a figure with a plot
  fig10 = figure(10);                                      % create a figure
  fig10.WindowStyle = "docked";                           % dock figures into one container
  [X,Y] = meshgrid(-5:.5:5);
  Z = Y.*sin(X) - X.*cos(Y) + 5000;
  surf(X,Y,Z,'FaceAlpha',0.8)  
  view(3);                                               % isometric view
  xlabel("x","FontName","Arial","FontSize",16);          % put x-label
  ylabel("y","FontName","Arial","FontSize",16);          % put y-label   
  zlabel("$\|\mathbf{u}\|$","FontName","Arial",...
         "FontSize",18,"Interpreter","latex");                % put z-label  
  nc10 = niceColorbar("modern","nice",12);                % instantiate a niceColorbar object
  nc10.ThemeMode = "cobalt";                                % theme mode
  nc10.Box = "off";                                       % turn off the axes box outline
  nc10.TickLabelsFontName = "Segoe UI";                   % declare tick labels font
  nc10.Title = {['(step = ',int2str(10),')'],...          % set title
                 '$\|\mathbf{u}\|$'};                            
  nc10.Logo = ['\color[rgb]{0.360784,0.4,0.435294}NICE',...
               '\color[rgb]{0.85,0.0,0.0}CLBR'];          % put a logo
  nc10.LogoFontName = "Impact";                           % declare logo font name 
  nc10.colorbar();                                        % create the colorbar   
  nc10.TickLabelsAutoScale = true;                        % autoscale tick labels and use 
  % scientific notation with common 
  % exponent to all tick labels
  nc10.TickLabelsAutoScaleDecimals = 2;                   % number of digits for tick labels
  % (TickLabelsFormat is ignored while
  % TickLabelsAutoScale is true)

  % save figure: called with no folder argument (as here), all
  % four methods write into a "SavedFigures" folder inside the
  % niceColorbar toolbox folder - NICE is the script-mode behavior. Calling
  % the same methods from niceColorbar.session() instead pops up a
  % folder-picker dialog (uigetdir) and saves wherever the user selects.
  % saveAsFIG() writes an editable .fig file (re-openable in MATLAB with
  % the colorbar and all its styling intact), unlike the PNG/TIFF/PDF exports.
  nc10.saveAsPNG();                                       % save figure as PNG image
  nc10.saveAsTIFF();                                      % save figure as TIFF image
  nc10.saveAsPDF();                                       % print figure to a PDF file
  nc10.saveAsFIG();                                       % save as MATLAB figure

end
