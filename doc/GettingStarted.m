%% Getting Started with niceColorbar
% Learning path: |QuickStart.m| -> Getting Started (you are here) ->
% |examples.m|
%
% niceColorbar is a styled, auto-refreshing replacement for MATLAB's
% |colorbar|. Build it once, then mutate properties afterward - the
% colorbar updates itself in place.

%% Build a colorbar with a style and colormap preset
figure
contourf(peaks)
xlabel("x", "FontName", "Arial", "FontSize", 14);
ylabel("y", "FontName", "Arial", "FontSize", 14);
nc = niceColorbar("ultra", "parula", 8);
nc.colorbar();

%% Add a LaTeX title
% Assigning |Title| after the colorbar is built auto-refreshes it - no
% need to call |colorbar()| again.
nc.Title = {'$u_{1,h}$'};

%% Style and colormap are swappable live
nc.Style = "modern.thick";
nc.ColormapName = "turbo";
nc.NumColormapColors = 12;

%% Color limits
% |setLimits| requires |colorbar()| to have run first (it did, above).
nc.setLimits([-6 6]);
nc.resetLimits();

%% Capped limits
% |setCappedLimits| clips out-of-range values to |CappedColorBelow|/
% |CappedColorAbove| instead of stretching the gradient over them.
nc.setCappedLimits([-4 4]);

%% Hiding pieces of a colorbar
% |ColorbarVisible|/|TitleVisible|/|LogoVisible| each independently
% hide/show just the bar, the title, or the logo, in place - the object,
% its build state, and every other property are untouched, so setting one
% back to |"on"| restores that exact element.
nc.TitleVisible = "off";
nc.TitleVisible = "on";
%%
% Setting all three together hides the colorbar entirely, e.g. for a clean
% screenshot of just the plot:
nc.ColorbarVisible = "off";
nc.TitleVisible = "off";
nc.LogoVisible = "off";
nc.ColorbarVisible = "on";
nc.TitleVisible = "on";
nc.LogoVisible = "on";

%% Side: right or left of the plot
% The colorbar (with its title and logo) defaults to the right of the
% plot; |Side = "left"| moves the whole thing to the left instead.
nc.Side = "left";
nc.Side = "right";

%% One colorbar per subplot
% |colorbar()| attaches to whichever axes is current (|gca|), so select
% each subplot with |axes(...)|/|subplot(...)| before calling it. Each
% instance keeps its own axes' footprint, so they don't expand over one
% another.
figure
ax1 = subplot(2,2,1);
contourf(peaks);
xlabel("x", "FontName", "Arial");
ylabel("y", "FontName", "Arial");
ncSub1 = niceColorbar("ultra", "parula", 8);
ncSub1.Title = {'Subplot 1'};
axes(ax1);
ncSub1.colorbar();

ax2 = subplot(2,2,2);
contourf(peaks(50));
xlabel("x", "FontName", "Arial");
ylabel("y", "FontName", "Arial");
ncSub2 = niceColorbar("modern.thick", "turbo", 12);
ncSub2.Title = {'Subplot 2'};
axes(ax2);
ncSub2.colorbar();

%% Works with 3-D plots too
% niceColorbar only reads/writes axes |Position|, so it attaches the same
% way to a 3-D plot (e.g. |surf|) as it does to a 2-D one (e.g. |contourf|)
% above.
figure
surf(peaks);
view(3);
xlabel("x", "FontName", "Arial");
ylabel("y", "FontName", "Arial");
zlabel("z", "FontName", "Arial");
nc3d = niceColorbar("ultra", "parula", 8);
nc3d.Title = {'3-D surf'};
nc3d.colorbar();

%% Saving figures to file
% |saveAsPNG|/|saveAsPDF| export the figure a colorbar is attached to.
% |saveAsFIG| instead saves an editable MATLAB |.fig| file, which reopens
% with the colorbar and all its styling intact. Called with no arguments
% (as here), files are auto-named from the figure number and a timestamp,
% and written to a "SavedFigures" folder inside the niceColorbar toolbox
% folder.
nc.saveAsPNG();
nc.saveAsPDF();
nc.saveAsFIG();
%%
% A folder and file name can also be given explicitly:
nc.saveAsPNG(pwd, "myFigure");
%%
% Calling the same methods from |niceColorbar.session()| (the |save.png|/
% |save.pdf|/|save.fig| commands) instead pops up a single |uiputfile|
% dialog to pick both the folder and file name interactively.

%% Next steps
% * See |examples.m| for a multi-figure walkthrough, including logos,
%   per-line title colors, and theme overrides.
% * Run |help niceColorbar| or |doc niceColorbar| for the full
%   property/method reference.
% * Call |niceColorbar.session()| at the command line for an interactive
%   console that adjusts whichever figure currently has focus.
