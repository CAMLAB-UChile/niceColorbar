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
  nc2 = niceColorbar("modern.thin","paraview",12);           % instantiate a niceColorbar object
  nc2.Side = "bottom";                                       % set colorbar on bottom    
  nc2.NumColormapColors = 10;                                % set number of colormapcolors
  nc2.ThemeMode = "dark";                                    % set theme mode  
  nc2.TickLabelsFontName = "Segoe UI";                       % set tick labels font
  nc2.TickLabelsFormat = '%+.2f';                            % set tick label format    
  nc2.Title = {['(step = ',int2str(10),') $\sigma$']};       % format the title (LATEX);
  nc2.TitleColor = [0.50,0.65,0.98];                         % custom color for title                                                         
  nc2.Logo = ['\color[rgb]{0.3608 0.4 0.43529}THIS',...      % format the logo
              '\color[rgb]{0.8 0.251 0.2235}LOGO'];      
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
  nc3.Title = {['\color[rgb]{0.28 0.57 0.87}(step = ',...    % format the title (TEX)
               int2str(10),'\color[rgb]{0.28 0.57 0.87})',...
               '\color[rgb]{0.95 0.67 0.03} u_{1,h}']};
  nc3.TitleInterpreter = "tex";                              % tex interpreter is essential
                                                             % if title is introduced in
                                                             % tex format
  nc3.Logo = ['\color[rgb]{0.3608 0.4 0.43529}THIS',...      % format the logo
              '\color[rgb]{0.8 0.251 0.2235}LOGO'];         
  nc3.LogoFontName = "Impact";                               % set logo font name
  nc3.colorbar();                                            % create the colorbar  

  %% figure 4: theme mode is explicitly set to light; colorbar on left;
  % colored title in LATEX format (default) and colored logo; 
  % capped colorbar limits
  fig4 = figure(4);                                          % create a figure
  fig4.WindowStyle = "docked";                               % dock figure into a container
  contourf(peaks);                                           % make a plot
  xlabel("x","FontName","Arial","FontSize",12);              % put the x-label
  ylabel("y","FontName","Arial","FontSize",12);              % put the y-label
  nc4 = niceColorbar("modern.thick","watermelon",12);        % instantiate a niceColorbar object
  nc4.Side = "left";                                         % set colorbar on left  
  nc4.NumColormapColors = 10;                                % set number of colormapcolors  
  nc4.TickLabelsFontName = "Segoe UI";                       % set tick labels font  
  nc4.ThemeMode = "light";                                   % set theme mode
  nc4.Title = {['(step = ',int2str(10),')'],...              % format the title (LATEX)
                '$\|\mathbf{u}\|$'};                         % first line auto-follows the theme color;
  nc4.TitleColor = {[],[0.17,0.61,0.39]};                    % custom color for the second line                                                              
  nc4.Logo = ['\color[rgb]{0.3608 0.4 0.43529}THIS',...      % format the logo
              '\color[rgb]{0.96 0.59 0.41}LOGO'];      
  nc4.LogoFontName = "Impact";                               % set logo font name
  nc4.colorbar();                                            % create the colorbar 
  nc4.setCappedLimits([-2.5 6.2])                            % set capped limits   

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
  nc5.Logo = ['\color[rgb]{0.3608 0.4 0.43529}THIS',...      % format the logo
              '\color[rgb]{0.8 0.251 0.2235}LOGO'];         
  nc5.LogoFontName = "Impact";                               % set logo font name
  nc5.colorbar();                                            % create the colorbar 

  %% figure 6: subplots (2d and 3d combined); colored title and logo; 
  % capped colorbar limits; colorbar on right, top, bottom, left;
  % theme mode explictly set to dark
  fig6 = figure(6);                                          % create a figure
  fig6.WindowStyle = "docked";                               % dock figure into a container

  subplot(2,2,1);                                            % first axes
  contourf(peaks);                                           % make a plot                                        
  xlabel("x","FontName","Arial","FontSize",12);              % put the x-label
  ylabel("y","FontName","Arial","FontSize",12);              % put the y-label
  nc6Sub1 = niceColorbar("ultra.thin","polar",8);            % instantiate a niceColorbar object
  nc6Sub1.ThemeMode = "dark";                                % set theme mode
  nc6Sub1.TickLabelsFontName = "Segoe UI";                   % set tick labels font 
  nc6Sub1.TickLabelsFontSize = 8;                            % set tick labels font size   
  nc6Sub1.Title = {'$\xi$'};                                 % format the title (LATEX)
  nc6Sub1.TitleFontSize = 20;                                % set title font size
  nc6Sub1.Logo = ['\color[rgb]{0.3608 0.4 0.43529}THIS',...  % format the logo
                  '\color[rgb]{0.8 0.251 0.2235}LOGO'];   
  nc6Sub1.LogoFontName = "Impact";                           % set logo font name  
  nc6Sub1.colorbar();                                        % create the colorbar   
  nc6Sub1.setCappedLimits([-4.2 5.6])                        % set capped limits   

  subplot(2,2,2);                                            % second axes
  contourf(peaks(50));                                       % make a plot 
  xlabel("x","FontName","Arial","FontSize",12);              % put the x-label
  ylabel("y","FontName","Arial","FontSize",12);              % put the y-label
  nc6Sub2 = niceColorbar("modern.thin","nice",8);            % instantiate a niceColorbar object
  nc6Sub2.ThemeMode = "dark";                                % set theme mode  
  nc6Sub2.TickLabelsFontName = "Segoe UI";                   % declare tick labels font    
  nc6Sub2.TickLabelsFontSize = 8;                            % set tick labels font size    
  nc6Sub2.TickLabelsFormat = '%+.2f';                        % set tick label format  
  nc6Sub2.Side = "top";                                      % set colorbar on top  
  nc6Sub2.Title = {'$\eta$'};                                % format the title (LATEX)
  nc6Sub2.TitleFontSize = 20;                                % set title font size   
  nc6Sub2.colorbar();                                        % create the colorbar    

  subplot(2,2,3);                                            % third axes
  surf(peaks(30),"EdgeColor",[0.2,0.2,0.2]);                 % make a plot 
  view(3);                                                   % isometric view                            
  xlabel("x","FontName","Arial","FontSize",12);              % put the x-label
  ylabel("y","FontName","Arial","FontSize",12);              % put the y-label
  zlabel("$\psi$","FontName","Arial","FontSize",12,...       % put the z-label 
         "Interpreter","latex");        
  nc6Sub3 = niceColorbar("ultra.thin","fast",10);            % instantiate a niceColorbar object
  nc6Sub3.ThemeMode = "dark";                                % set theme mode  
  nc6Sub3.Side = "bottom";                                   % set colorbar on bottom 
  nc6Sub3.TickLabelsFontName = "Segoe UI";                   % declare tick labels font   
  nc6Sub3.TickLabelsFontSize = 8;                            % set tick labels font size     
  nc6Sub3.TickLabelsFormat = '%+.2f';                        % set tick label format
  nc6Sub3.Title = {'$\psi$'};                                % format the title
  nc6Sub3.TitleFontSize = 20;                                % set title font size 
  nc6Sub3.TitleColor = {[0.44,0.80,0.95]};                   % custom color for title 
  nc6Sub3.colorbar();                                        % create the colorbar   

  subplot(2,2,4);                                            % fourth axes
  contourf(peaks(40));                                       % make a plot 
  xlabel("x","FontName","Arial","FontSize",12);              % put the x-label
  ylabel("y","FontName","Arial","FontSize",12);              % put the y-label
  nc6Sub4 = niceColorbar("modern.thin","cork",8);            % instantiate a niceColorbar object
  nc6Sub4.ThemeMode = "dark";                                % set theme mode  
  nc6Sub4.TickLabelsFontName = "Segoe UI";                   % declare tick labels font    
  nc6Sub4.TickLabelsFontSize = 8;                            % set tick labels font size     
  nc6Sub4.Side = "left";                                     % set colorbar on left  
  nc6Sub4.Title = {['(step = ',int2str(10),')'],...          % format the title
                   '$\|\mathbf{u}\|$'};
  nc6Sub4.TitleColor = {[0.28,0.57,0.87],[0.17,0.61,0.39]};  % custom color for title 
  nc6Sub4.TitleFontSize = 16;                                % set title font size   
  nc6Sub4.Logo = ['\color[rgb]{0.3608 0.4 0.43529}THIS',...  % format the logo
                 '\color[rgb]{0.8 0.251 0.2235}LOGO'];         
  nc6Sub4.LogoFontName = "Impact";                           % set logo font name  
  nc6Sub4.colorbar();                                        % create the colorbar 
  nc6Sub4.setCappedLimits([-4.2 5.6])                        % set capped limits   

  %% figure 7: subplots (2d and 3d combined); colored title and logo; 
  % capped colorbar limits; colorbar on right, top, bottom, left;
  % theme mode explictly set to light
  fig7 = figure(7);                                          % create a figure
  fig7.WindowStyle = "docked";                               % dock figure into a container

  subplot(2,2,1);                                            % first axes
  contourf(peaks);                                           % make a plot                                        
  xlabel("x","FontName","Arial","FontSize",12);              % put the x-label
  ylabel("y","FontName","Arial","FontSize",12);              % put the y-label
  nc7Sub1 = niceColorbar("ultra.thin","polar",8);            % instantiate a niceColorbar object
  nc7Sub1.ThemeMode = "light";                               % set theme mode 
  nc7Sub1.TickLabelsFontName = "Segoe UI";                   % set tick labels font 
  nc7Sub1.TickLabelsFontSize = 8;                            % set tick labels font size   
  nc7Sub1.Title = {'$\xi$'};                                 % format the title (LATEX) 
  nc7Sub1.TitleFontSize = 20;                                % set title font size  
  nc7Sub1.Logo = ['\color[rgb]{0.3608 0.4 0.43529}THIS',...  % format the logo
                  '\color[rgb]{0.8 0.251 0.2235}LOGO'];   
  nc7Sub1.LogoFontName = "Impact";                           % set logo font name   
  nc7Sub1.colorbar();                                        % create the colorbar   
  nc7Sub1.setCappedLimits([-4.2 5.6])                        % set capped limits   

  subplot(2,2,2);                                            % second axes
  contourf(peaks(50));                                       % make a plot 
  xlabel("x","FontName","Arial","FontSize",12);              % put the x-label
  ylabel("y","FontName","Arial","FontSize",12);              % put the y-label
  nc7Sub2 = niceColorbar("modern.thin","nice",8);            % instantiate a niceColorbar object
  nc7Sub2.ThemeMode = "light";                               % set theme mode   
  nc7Sub2.TickLabelsFontName = "Segoe UI";                   % declare tick labels font    
  nc7Sub2.TickLabelsFontSize = 8;                            % set tick labels font size    
  nc7Sub2.TickLabelsFormat = '%+.2f';                        % set tick label format  
  nc7Sub2.Side = "top";                                      % set colorbar on top  
  nc7Sub2.Title = {'$\eta$'};                                % format the title (LATEX)
  nc7Sub2.TitleFontSize = 20;                                % set title font size  
  nc7Sub2.colorbar();                                        % create the colorbar    

  subplot(2,2,3);                                            % third axes
  surf(peaks(30),"EdgeColor",[0.2,0.2,0.2]);                 % make a plot 
  view(3);                                                   % isometric view                            
  xlabel("x","FontName","Arial","FontSize",12);              % put the x-label
  ylabel("y","FontName","Arial","FontSize",12);              % put the y-label
  zlabel("$\psi$","FontName","Arial","FontSize",12,...       % put the z-label 
         "Interpreter","latex");        
  nc7Sub3 = niceColorbar("ultra.thin","fast",10);            % instantiate a niceColorbar object
  nc7Sub3.ThemeMode = "light";                               % set theme mode   
  nc7Sub3.Side = "bottom";                                   % set colorbar on bottom 
  nc7Sub3.TickLabelsFontName = "Segoe UI";                   % declare tick labels font   
  nc7Sub3.TickLabelsFontSize = 8;                            % set tick labels font size     
  nc7Sub3.TickLabelsFormat = '%+.2f';                        % set tick label format
  nc7Sub3.Title = {'$\psi$'};                                % format the title
  nc7Sub3.TitleFontSize = 20;                                % set title font size  
  nc7Sub3.TitleColor = {[0.17,0.31,0.70]};                   % custom color for title 
  nc7Sub3.colorbar();                                        % create the colorbar   

  subplot(2,2,4);                                            % fourth axes
  contourf(peaks(40));                                       % make a plot 
  xlabel("x","FontName","Arial","FontSize",12);              % put the x-label
  ylabel("y","FontName","Arial","FontSize",12);              % put the y-label
  nc7Sub4 = niceColorbar("modern.thin","cork",8);            % instantiate a niceColorbar object
  nc7Sub4.ThemeMode = "light";                               % set theme mode   
  nc7Sub4.TickLabelsFontName = "Segoe UI";                   % declare tick labels font    
  nc7Sub4.TickLabelsFontSize = 8;                            % set tick labels font size     
  nc7Sub4.Side = "left";                                     % set colorbar on left  
  nc7Sub4.Title = {['(step = ',int2str(10),')'],...          % format the title
                   '$\|\mathbf{u}\|$'};
  nc7Sub4.TitleColor = {[0.17,0.31,0.70],[0.17,0.61,0.39]};  % custom color for title  
  nc7Sub4.TitleFontSize = 16;                                % set title font size   
  nc7Sub4.Logo = ['\color[rgb]{0.3608 0.4 0.43529}THIS',...  % format the logo
                  '\color[rgb]{0.8 0.251 0.2235}LOGO'];         
  nc7Sub4.LogoFontName = "Impact";                           % set logo font name  
  nc7Sub4.colorbar();                                        % create the colorbar 
  nc7Sub4.setCappedLimits([-4.2 5.6])                        % set capped limits   

end
