classdef niceColorbar < handle
  %NICECOLORBAR Styled, auto-refreshing colorbar with title and logo text.
  %   NC = NICECOLORBAR(STYLE, COLORMAPNAME, NUMCOLORMAPCOLORS) creates a
  %   niceColorbar object. Call NC.colorbar() to build the colorbar on the
  %   current axes; thereafter, changing any property (e.g. NC.Title) or
  %   figure size auto-refreshes the colorbar in place.
  %
  %   See also NICECOLORBAR/COLORBAR, NICECOLORBAR/SETLIMITS,
  %   NICECOLORBAR/SETCAPPEDLIMITS, NICECOLORBAR/RESETLIMITS.

  % Author: Alejandro Ortiz-Bernardin, aortizb@uchile.cl, camlab.cl/alejandro

  properties (SetObservable, AbortSet) % default properties
    % SetObservable + AbortSet is what enables auto-update: every one of
    % these fires a PostSet event when it actually changes value (AbortSet
    % suppresses the event if you reassign the same value), and that event
    % is what drives refresh() below once the colorbar has been built.
    ThemeMode = "auto" % 'auto' follows MATLAB's current light/dark mode; 'light' or 'dark'
                       % forces that look regardless of MATLAB's actual theme
    TickLabelsFontName = "Times New Roman" %'Segoe UI Semibold';
    TickLabelsFontSize = 10
    TickLabelsFontWeight = "normal"
    TickLabelsFormat = '%+.2e' % '%+.2e', '%.2e', '%.2f', '%.4e', '%.4f', etc
    TickLabelsAutoScale = false % when true, tick VALUES/Limits/clim stay in real data
                                % units, but tick LABELS are divided by 10^n before being
                                % formatted, and a "x10^n" line is auto-prepended above
                                % Title (rendered with TitleInterpreter, matching Title's
                                % own styling). n = floor(log10(max(abs(current Limits))));
                                % n=0 (values already order-1) suppresses scaling/annotation
                                % entirely. E.g. Limits [-3e-3 4e-3] -> n=-3, ticks label as
                                % -3,-2,0,1,3,4 with "x10^-3" shown above the bar.
                                % While TickLabelsAutoScale is true, tick labels always use
                                % '%+.<TickLabelsAutoScaleDecimals>f' instead of
                                % TickLabelsFormat - a scaled value like -3 read alongside
                                % an exponential TickLabelsFormat (e.g. '%+.2e') would be
                                % confusing, so autoscale mode owns its own fixed-point format.
    TickLabelsAutoScaleDecimals = 2 % number of decimal digits used by the '%+.<n>f' format
                                    % that overrides TickLabelsFormat while TickLabelsAutoScale
                                    % is true; ignored otherwise
    TickLineWidth = 1.0
    TickLineColor = "k" % used only when colorbar lines are not hidden
    Title = {} % {['(step = ',int2str(10),')'],'$u_{1,h}$'};
    TitleInterpreter = "latex"
    TitleFontName = "Times New Roman"
    TitleFontSize = 18
    TitleFontWeight = "bold"
    TitleColor = [] % [] auto-follows the theme for the whole Title; a single color/RGB triplet
                     % overrides the whole Title; a cell array matching Title's lines (each entry
                     % [] or a color) colors each line independently
    Logo = {} %['\color[rgb]{0.360784,0.4,0.435294}THIS','\color[rgb]{0.8000,0.2510,0.2235}LOGO'];
    LogoFontName = "Times New Roman" %'Segoe UI Semibold';
    LogoFontSize = 16
    LogoFontWeight = "normal"
    Style               % 'modern', 'modern.thin', 'modern.thick', 'ultra', 'ultra.thin', 'ultra.thick'
    ColormapName        % matlab's colormap library: 'jet', 'turbo', 'parula', 'nebula', 'abyss',
                        % 'sky', 'winter', 'cool', etc.
    NumColormapColors   % positive number
    CappedColorBelow = [0.6 0.6 0.6] % color used at/below the capped min limit (see setCappedLimits)
    CappedColorAbove = [0 0 0]       % color used at/above the capped max limit (see setCappedLimits)
    % ColorbarVisible/TitleVisible/LogoVisible independently hide/show the
    % bar itself, the title text, and the logo text - each 'on' by default.
    % None of them discard or rebuild anything: setting one back to 'on'
    % restores that exact element. To hide/show everything at once, set
    % all three together (see niceColorbar.session()'s hide.all/show.all).
    ColorbarVisible = "on"
    TitleVisible = "on"
    LogoVisible = "on"
    Side = "right" % 'right' (default), 'left', 'top', or 'bottom' - which side of
                   % the plot the colorbar (with its title and logo) is placed on.
                   % For 'top'/'bottom' the colorbar runs horizontally, with the
                   % Title to its left and the Logo to its right, both read
                   % horizontally (unlike 'left'/'right', where Title sits above
                   % and Logo below a vertical colorbar).
    PdfRender = "image" % 'image' (default) or 'vector' - exportgraphics'
                        % ContentType used by saveAsPDF()/session()'s save.pdf.
                        % 'vector' preserves crisp, infinitely-scalable text/lines
                        % but is slow and prone to exportgraphics' own
                        % "Vectorized content might take a long time..." warning
                        % (suppressed automatically while 'vector' is selected -
                        % see saveFigureAs()); 'image' rasterizes instead, same
                        % as saveAsPNG(), trading scalability for speed/reliability.
    ExportResolution = 300 % pixels-per-inch used by saveAsPNG() and by saveAsPDF()
                           % while PdfRender is 'image' - exportgraphics ignores it
                           % entirely for PdfRender='vector' (vector content has no
                           % fixed resolution).
  end

  properties (Access = private)
    fig    % figure container object
    ax     % current axes object
    clb    % colorbar object
    ylb    % Logo text object, parented to ax (not to clb - see applyProperties
           % for why: unlike a colorbar's Title, its native Label/ylabel is
           % tied to the axis ruler and goes invisible along with the
           % colorbar itself, which would make LogoVisible impossible to
           % keep independent of ColorbarVisible)
    ExpLabelObj % TickLabelsAutoScale's auto "x10^n" annotation, parented to ax
                % (or a figure-level annotation textbox for a 3-D axes) exactly
                % like ylb above - a standalone object, deliberately kept
                % separate from TitleLineObjs so it never consumes/renumbers
                % the user's own Title lines or TitleColor entries
    ZExpLabelObj % standalone stand-in for a 3-D axes' native ZAxis.SecondaryLabel
                % ("x10^n" text) while TickLabelsAutoScale is on - the native
                % object is hidden (never repositioned directly: writing its
                % Position even once permanently disables MATLAB's own
                % adaptive camera-tracking placement for it, verified
                % empirically - toggling ExponentMode/Visible/Exponent
                % afterward never restores it). This mirrors it instead: a
                % plain text() in 'data' units, parented to ax, positioned
                % from the native label's own still-live Position each
                % applyProperties call (offset 20 px up) - being a normal
                % 3-D data-space object, it re-projects with the camera
                % automatically between calls exactly like the native ticks,
                % no per-frame polling needed
    Built = false     % true once colorbar() has run at least once
    PropListener      % PostSet listener driving auto-refresh on mutation
    ViewListener      % PostSet listener on obj.ax's View, driving a cheap
                       % re-layout after interactive 3-D rotation (see colorbar())
    SettleTimer       % reused singleShot timer (stop+restart, not recreated -
                       % see scheduleSettleRefresh) that polls until rotation
                       % OR a plain resize truly settles, then runs one
                       % accurate, live-measured layout pass
    SettlePollMarker  % obj.ax's last-observed pixel Position while polling for
                       % settlement (see onSettleRefresh) - [] between bursts
    SettlePollCount = 0 % number of consecutive settle-poll retries so far this
                       % burst, capped in onSettleRefresh
    LastKnownFigPos   % obj.fig's pixel Position as of the last
                       % pollForMissedResize() check - see that method
    LastKnownAxPos    % obj.ax's pixel Position as of the last
                       % pollForMissedResize() check - see that method
    SuspendRefresh = false % true while batching several property writes (e.g.
                            % hide.all/show.all) into a single refresh(), so
                            % the layout doesn't visibly flash through the
                            % in-between states of a multi-property change
    ResizeLayout       % layout struct cached for the SizeChangedFcn hot path
    TickLabelExtent = [0 0] % [width height] of the widest current tick label,
                            % cached here (computed once per applyProperties call,
                            % NOT per resize tick) for positioning the
                            % TickLabelsAutoScale exponent annotation - see
                            % measureTickLabelExtent()/updateColorbarLayout
    TitleLineObjs = {} % one text object per Title line, used only in per-line TitleColor mode (see applyProperties)
    ThemeBgColor = [1 1 1]   % background color, set from MATLAB's light/dark mode at build time
    ThemeFontColor = [0 0 0] % font/axes-line color, set from MATLAB's light/dark mode at build time
    OriginalLimits = []      % clim captured at build time; used by resetLimits()
    OriginalAxesPosition = [] % normalized axes Position captured at build time;
                              % the layout footprint updateColorbarLayout fits
                              % into, so a subplot axes keeps its own tile
                              % instead of expanding to fill the whole figure
    Capped = false           % true after setCappedLimits(); cleared by setLimits()/resetLimits()
    CappedLimits = []        % [minVal maxVal] passed to the most recent setCappedLimits() call
    Top3DGapFrac = 0.35      % Side='top' on a 3-D axes only: extra headroom above the heuristic
                             % content bbox, as a fraction of its measured height. Re-measured live
                             % (via rasterization - see updateColorbarLayout) whenever allowed; the
                             % 0.35 default only matters before the first such measurement runs.
  end

  methods
    % constructor
    function obj = niceColorbar(styleVal,ColormapNameVal,NumColormapColorsVal)
      arguments % argument check that serves as a default constructor
        styleVal {mustBeMember(styleVal,{'modern','modern.thin','modern.thick',...
                  'ultra','ultra.thin','ultra.thick'})} = 'ultra'
        ColormapNameVal {mustBeText} = 'ultra'
        NumColormapColorsVal {mustBeInteger, mustBePositive} = 8
      end
      obj.Style = styleVal;
      obj.ColormapName = ColormapNameVal;
      obj.NumColormapColors = NumColormapColorsVal;
      % Note: these three assignments do fire PostSet, but PropListener
      % doesn't exist yet at this point (it's only created inside
      % colorbar(), after the first build), so refresh() never runs here.
    end

    % ---- set methods ----------------------------------------------------
    % All setters funnel through the private static helper checkAndAssign,
    % which runs the validator(s), raises a niceColorbar-specific error with
    % a friendly message on failure, and otherwise performs the assignment.
    % This replaces ~170 lines of copy-pasted try/catch blocks with the
    % same behavior in a fraction of the code.

    function set.ThemeMode(obj,val)
      checkAndAssign('ThemeMode',val,{@(v)mustBeMember(v,{'auto','light','dark'})}, ...
        'value must be ''auto'', ''light'', or ''dark'' ');
      obj.ThemeMode = val;
    end
    function set.TickLabelsFontName(obj,val)
      checkAndAssign('TickLabelsFontName',val,{@mustBeText}, ...
        'value must be a string array or character vector');
      obj.TickLabelsFontName = val;
    end
    function set.TickLabelsFontSize(obj,val)
      checkAndAssign('TickLabelsFontSize',val,{@mustBeInteger,@mustBeNonnegative}, ...
        'value must be a nonnegative integer');
      obj.TickLabelsFontSize = val;
    end
    function set.TickLabelsFontWeight(obj,val)
      checkAndAssign('TickLabelsFontWeight',val,{@(v)mustBeMember(v,{'normal','bold'})}, ...
        'value must be ''normal'' or ''bold'' ');
      obj.TickLabelsFontWeight = val;
    end
    function set.TickLabelsFormat(obj,val)
      checkAndAssign('TickLabelsFormat',val,{@mustBeText}, ...
        'value must be a character vector');
      obj.TickLabelsFormat = val;
    end
    function set.TickLabelsAutoScale(obj,val)
      checkAndAssign('TickLabelsAutoScale',val,{@(v)mustBeMember(v,[true false])}, ...
        'value must be a logical scalar');
      obj.TickLabelsAutoScale = val;
    end
    function set.TickLabelsAutoScaleDecimals(obj,val)
      checkAndAssign('TickLabelsAutoScaleDecimals',val,{@mustBeInteger,@mustBeNonnegative}, ...
        'value must be a nonnegative integer');
      obj.TickLabelsAutoScaleDecimals = val;
    end
    function set.TickLineWidth(obj,val)
      checkAndAssign('TickLineWidth',val,{@mustBeNumeric,@mustBeNonnegative}, ...
        'value must be a nonnegative number');
      obj.TickLineWidth = val;
    end
    function set.TickLineColor(obj,val)
      checkAndAssign('TickLineColor',val,{@mustBeColorSpec}, ...
        'value must be a color name, character vector, or 1x3 RGB triplet with components in [0,1]');
      obj.TickLineColor = val;
    end
    function set.Title(obj,val)
      checkAndAssign('Title',val,{@mustBeText}, ...
        'value must be a string array, character vector, or cell array of character vectors');
      obj.Title = val;
    end
    function set.TitleInterpreter(obj,val)
      checkAndAssign('TitleInterpreter',val,{@(v)mustBeMember(v,{'tex','latex','none'})}, ...
        'value must be ''tex'', ''latex'', or ''none'' ');
      obj.TitleInterpreter = val;
    end
    function set.TitleFontName(obj,val)
      checkAndAssign('TitleFontName',val,{@mustBeText}, ...
        'value must be a character vector');
      obj.TitleFontName = val;
    end
    function set.TitleFontSize(obj,val)
      checkAndAssign('TitleFontSize',val,{@mustBeInteger,@mustBeNonnegative}, ...
        'value must be a nonnegative integer');
      obj.TitleFontSize = val;
    end
    function set.TitleFontWeight(obj,val)
      checkAndAssign('TitleFontWeight',val,{@(v)mustBeMember(v,{'normal','bold'})}, ...
        'value must be ''normal'' or ''bold'' ');
      obj.TitleFontWeight = val;
    end
    function set.TitleColor(obj,val)
      checkAndAssign('TitleColor',val,{@mustBeTitleColorSpec}, ...
        ['value must be empty (auto-follow the theme), a color name/character vector/1x3 RGB triplet ', ...
         '(applies to the whole Title), or a cell array of those (each may be empty) to color each ', ...
         'Title line independently']);
      obj.TitleColor = val;
    end
    function set.Logo(obj,val)
      checkAndAssign('Logo',val,{@mustBeText}, ...
        'value must be a string array, character vector, or cell array of character vectors');
      obj.Logo = val;
    end
    function set.LogoFontName(obj,val)
      checkAndAssign('LogoFontName',val,{@mustBeText}, ...
        'value must be a character vector');
      obj.LogoFontName = val;
    end
    function set.LogoFontSize(obj,val)
      checkAndAssign('LogoFontSize',val,{@mustBeInteger,@mustBeNonnegative}, ...
        'value must be a nonnegative integer');
      obj.LogoFontSize = val;
    end
    function set.LogoFontWeight(obj,val)
      checkAndAssign('LogoFontWeight',val,{@(v)mustBeMember(v,{'normal','bold'})}, ...
        'value must be ''normal'' or ''bold'' ');
      obj.LogoFontWeight = val;
    end
    function set.Style(obj,val)
      checkAndAssign('Style',val, ...
        {@(v)mustBeMember(v,{'modern','modern.thin','modern.thick','ultra','ultra.thin','ultra.thick'})}, ...
        'value must be ''modern'', ''modern.thin'', ''modern.thick'', ''ultra'', ''ultra.thin'', ''ultra.thick'' ');
      obj.Style = val;
    end
    function set.ColormapName(obj,val)
      validNames = getValidColormapNames();
      checkAndAssign('ColormapName',val,{@mustBeText,@(v)mustBeMember(v,validNames)}, ...
        sprintf('value must be one of:\n%s',wrapCommaList(validNames,100)));
      obj.ColormapName = val;
    end
    function set.NumColormapColors(obj,val)
      checkAndAssign('NumColormapColors',val,{@mustBeInteger,@mustBeNonnegative}, ...
        'value must be a nonnegative integer');
      obj.NumColormapColors = val;
    end
    function set.CappedColorBelow(obj,val)
      checkAndAssign('CappedColorBelow',val,{@mustBeColorSpec}, ...
        'value must be a color name, character vector, or 1x3 RGB triplet with components in [0,1]');
      obj.CappedColorBelow = val;
    end
    function set.CappedColorAbove(obj,val)
      checkAndAssign('CappedColorAbove',val,{@mustBeColorSpec}, ...
        'value must be a color name, character vector, or 1x3 RGB triplet with components in [0,1]');
      obj.CappedColorAbove = val;
    end
    function set.ColorbarVisible(obj,val)
      checkAndAssign('ColorbarVisible',val,{@(v)mustBeMember(v,{'on','off'})}, ...
        'value must be ''on'' or ''off'' ');
      obj.ColorbarVisible = val;
    end
    function set.TitleVisible(obj,val)
      checkAndAssign('TitleVisible',val,{@(v)mustBeMember(v,{'on','off'})}, ...
        'value must be ''on'' or ''off'' ');
      obj.TitleVisible = val;
    end
    function set.LogoVisible(obj,val)
      checkAndAssign('LogoVisible',val,{@(v)mustBeMember(v,{'on','off'})}, ...
        'value must be ''on'' or ''off'' ');
      obj.LogoVisible = val;
    end
    function set.Side(obj,val)
      checkAndAssign('Side',val,{@(v)mustBeMember(v,{'right','left','top','bottom'})}, ...
        'value must be ''right'', ''left'', ''top'', or ''bottom'' ');
      obj.Side = val;
    end
    function set.PdfRender(obj,val)
      checkAndAssign('PdfRender',val,{@(v)mustBeMember(v,{'vector','image'})}, ...
        'value must be ''vector'' or ''image'' ');
      obj.PdfRender = val;
    end
    function set.ExportResolution(obj,val)
      checkAndAssign('ExportResolution',val,{@mustBeInteger,@mustBePositive}, ...
        'value must be a positive integer');
      obj.ExportResolution = val;
    end

  end

  methods (Access = public)

    function colorbar(obj)
      %COLORBAR Build (or rebuild) the styled colorbar on the current axes.
      % Deliberately named to match MATLAB's built-in colorbar() for a
      % drop-in feel. This is safe: the method is only reachable via dot
      % notation (obj.colorbar()), so the bare colorbar(...) call below
      % resolves to the built-in, not a recursive call into this method.
      %% figure and axes settings
      obj.ax = gca;
      obj.fig = ancestor(obj.ax,'figure');
      obj.resolveTheme();
      box on;
      axis equal;

      % capture the axes' normalized Position as it stands right now (i.e.
      % before this method starts resizing it), so updateColorbarLayout can
      % fit its box into that same footprint instead of assuming the axes
      % owns the whole figure - this is what lets several niceColorbar
      % instances coexist on one figure (e.g. one per subplot)
      obj.ax.Units = "normalized";
      obj.OriginalAxesPosition = obj.ax.Position;

      % capture the data's color limits as they stand right now (i.e.
      % before any setLimits() call), so resetLimits() has an "original"
      % to revert to later
      obj.OriginalLimits = clim(obj.ax);

      % a fresh build should never carry over capped-mode state from a
      % previous build (e.g. colorbar() called again to rebind to a new
      % axes)
      obj.Capped = false;
      obj.CappedLimits = [];

      % if colorbar() is called again (e.g. to rebind to a new axes),
      % clear out anything left over from a previous build so we don't
      % leak a duplicate colorbar/logo graphics object
      if ~isempty(obj.clb) && isvalid(obj.clb)
        delete(obj.clb);
      end
      obj.clb = [];
      % the Logo (obj.ylb) and per-line Title text objects (see
      % applyProperties) are parented to the axes, not the colorbar, so
      % deleting obj.clb above doesn't clean them up - drop them explicitly
      % before (re)building
      if ~isempty(obj.ylb) && isvalid(obj.ylb)
        delete(obj.ylb);
      end
      obj.ylb = [];
      if ~isempty(obj.ExpLabelObj) && isvalid(obj.ExpLabelObj)
        delete(obj.ExpLabelObj);
      end
      obj.ExpLabelObj = [];
      for i = 1:numel(obj.TitleLineObjs)
        if isvalid(obj.TitleLineObjs{i})
          delete(obj.TitleLineObjs{i});
        end
      end
      obj.TitleLineObjs = {};

      %% create a colorbar: this is the in-built MATLAB's colorbar that is wrapped by 
      % niceColorbar's colorbar public method
      obj.clb = colorbar("FontName",obj.TickLabelsFontName,"FontSize",obj.TickLabelsFontSize,...
                         "FontWeight",obj.TickLabelsFontWeight,"LineWidth",obj.TickLineWidth,...
                         "Color",obj.TickLineColor);

      % mark built BEFORE applying properties, since applyProperties() is
      % the same routine refresh() calls later - guarding on obj.Built is
      % what lets refresh() safely no-op on any PostSet event that manages
      % to fire before a colorbar actually exists
      obj.Built = true;

      %% title / logo / colormap / ticks / layout - see applyProperties()
      obj.applyProperties();

      % run the layout alignment helper once immediately to set the
      % starting view (applyProperties already iterates this a few times
      % to let it settle), then keep it in sync on every figure resize.
      % onResize() re-reads obj.Style-derived layout fresh from
      % obj.ResizeLayout each time, so it never uses a stale closure.
      %
      % Registering through resizeHub (rather than assigning
      % obj.fig.SizeChangedFcn directly) is what lets more than one
      % niceColorbar share the same figure - e.g. one per subplot. A plain
      % `set(obj.fig,'SizeChangedFcn',@(~,~) obj.onResize())` here would
      % have each new instance clobber the previous one's callback, so only
      % the most-recently-built colorbar in a figure would ever re-align on
      % resize.
      niceColorbar.resizeHub('register',obj.fig,obj);
      set(obj.fig,'SizeChangedFcn',@(src,~) niceColorbar.resizeHub('dispatch',src));

      %% SizeChangedFcn does NOT reliably fire for every way a figure can
      % resize either: confirmed, via direct testing in a live session,
      % that toggling the desktop's "maximize figure" toolstrip icon on a
      % DOCKED figure changes obj.fig.Position (verified correct
      % immediately afterward) WITHOUT ever invoking SizeChangedFcn - so
      % onResize() (and everything it schedules) silently never runs,
      % leaving the colorbar/Title/Logo exactly where they were before the
      % toggle. A plain drag-resize of the same docked panel, by contrast,
      % fires SizeChangedFcn correctly every time - this gap is specific to
      % that one toolstrip interaction. Figure's own Position property also
      % isn't SetObservable (addlistener errors), so there's no PostSet
      % event to hook instead - a low-frequency poll is the only way left
      % to catch this. Checking obj.fig.Position (a cheap read) once a
      % second and only invoking onResize() when it actually changed keeps
      % the ongoing cost negligible; reuses the exact same
      % onResize->scheduleSettleRefresh pipeline a real SizeChangedFcn event
      % would have driven, so the fix for THAT lag (see onSettleRefresh)
      % applies here too.
      %
      % A background 1Hz poll is only worth running while obj.fig is
      % visible - the toolstrip interaction it exists to catch can only
      % ever happen on a figure the user can actually see and click on -
      % which this checks fresh on every shared-timer tick (see
      % sharedPollTimer) rather than starting/stopping a per-instance timer
      % off a 'Visible' PostSet listener the way an earlier version did.
      %
      % ONE shared timer for every live niceColorbar instance (rather than
      % one independent timer per instance) - an earlier per-instance
      % design was suspected of contributing to a rare but serious bug:
      % docking several figures into one group at once could leave a
      % docked tab rendering another tab's stale/duplicated colorbar
      % content, and that bug tracked with the NUMBER of independently
      % ticking timers all reacting to the same external dock event on
      % their own schedule (each doing its own drawnow/Position-write) -
      % a controlled comparison against plain MATLAB colorbar (same
      % figure/subplot count, zero of niceColorbar's background timers)
      % came back clean, isolating niceColorbar's own machinery as the
      % likely factor. One coordinated pass per tick, over every
      % registered instance, replaces that race with a single-threaded
      % sweep - mirroring how resizeHub already centralizes SizeChangedFcn
      % dispatch for the same reason.
      obj.LastKnownFigPos = [];
      obj.LastKnownAxPos = [];
      niceColorbar.sharedPollTimer('ensure');

      %% keep the layout in sync with interactive 3-D rotation too. Unlike
      % a plain window resize (always fires SizeChangedFcn), rotating a
      % 3-D view via the axes toolbar's Rotate button doesn't touch figure
      % size at all - and rotate3d's ActionPostCallback, tried here first,
      % was found not to reliably fire for that modern interaction either -
      % so without this, the colorbar/Title/Logo (positioned for whatever
      % view was current at the last property change or colorbar() call)
      % would silently go stale the instant the user rotates further. The
      % axes' own View property, by contrast, changes for every rotation
      % mechanism uniformly (mouse drag, axtoolbar, or a plain view() call)
      % since it's what MATLAB itself updates under the hood.
      %
      % onViewChanged() (see its own comment) runs a cheap position-only
      % update immediately on every View change for responsiveness during
      % a drag, then schedules an accurate, live-measured pass via a
      % reused singleShot timer once rotation settles - needed because the
      % cheap pass alone was found insufficient: at near-edge-on elevation,
      % if the user stops rotating right after the cheap pass reused a
      % badly-fitting gap fraction from an earlier, very different
      % rotation, nothing would otherwise ever correct it.
      if ~isempty(obj.ViewListener) && isvalid(obj.ViewListener)
        delete(obj.ViewListener);
      end
      obj.ViewListener = addlistener(obj.ax,'View','PostSet',@(~,~) obj.onViewChanged());
      % stop/delete a still-pending settle timer if the axes closes out
      % from under it (e.g. the figure is closed mid-rotation), rather than
      % leaving a running timer (and its captured reference to obj)
      % dangling.
      addlistener(obj.ax,'ObjectBeingDestroyed',@(~,~) obj.cancelSettleRefresh());

      %% wire up auto-refresh: from this point on, mutating any public
      % property (Title, Style, ColormapName, fonts, etc.) automatically
      % re-applies it to the live colorbar - no need to call colorbar()
      % again by hand.
      if isempty(obj.PropListener)
        obj.PropListener = addlistener(obj, properties(obj), 'PostSet', @(~,~) obj.refresh());
      end
    end

    function setLimits(obj,newLimits)
      % Sets the colorbar/axes color limits to newLimits = [minVal maxVal].
      % Unlike the SetObservable properties above, this bypasses the
      % property-listener refresh mechanism entirely - color limits live on
      % the axes (clim), not on this object - so it applies the change and
      % re-derives ticks/labels directly via applyProperties().
      arguments
        obj
        newLimits (1,2) double {mustBeNumeric,mustBeFinite}
      end
      if ~obj.Built || isempty(obj.ax) || ~isvalid(obj.ax)
        error('niceColorbar:setLimits:notBuilt','colorbar() must be called before setLimits()');
      end
      if newLimits(2) <= newLimits(1)
        error('niceColorbar:setLimits:invalidValue','max value must be greater than min value');
      end
      obj.Capped = false; % a plain setLimits() always leaves/overrides capped mode
      clim(obj.ax,newLimits);
      obj.applyProperties();
    end

    function setCappedLimits(obj,newLimits)
      % Like setLimits(), but instead of stretching the existing gradient
      % colormap over the new range, caps it: values at/below newLimits(1)
      % render as obj.CappedColorBelow and values at/above newLimits(2)
      % render as obj.CappedColorAbove, with the normal NumColormapColors
      % gradient in between. See setCappedColorbarLevels() for the actual
      % colormap/tick construction - this method only records the request
      % and re-triggers it.
      arguments
        obj
        newLimits (1,2) double {mustBeNumeric,mustBeFinite}
      end
      if ~obj.Built || isempty(obj.ax) || ~isvalid(obj.ax)
        error('niceColorbar:setCappedLimits:notBuilt','colorbar() must be called before setCappedLimits()');
      end
      if newLimits(2) <= newLimits(1)
        error('niceColorbar:setCappedLimits:invalidValue','max value must be greater than min value');
      end
      obj.Capped = true;
      obj.CappedLimits = newLimits;
      obj.applyProperties();
    end

    function resetLimits(obj)
      % Reverts the color limits to whatever they were when colorbar() was
      % first called (captured in obj.OriginalLimits), and clears capped
      % mode if setCappedLimits() had been used.
      if ~obj.Built || isempty(obj.ax) || ~isvalid(obj.ax)
        error('niceColorbar:resetLimits:notBuilt','colorbar() must be called before resetLimits()');
      end
      obj.Capped = false;
      obj.CappedLimits = [];
      if isempty(obj.OriginalLimits)
        return
      end
      clim(obj.ax,obj.OriginalLimits);
      obj.applyProperties();
    end

    function saveAsPNG(obj,folder,fileName)
      % Exports the figure this colorbar is attached to as a PNG image.
      % folder and fileName are both optional: called with no arguments
      % (e.g. from a script like examples.m), a name is auto-generated from
      % the figure number and a timestamp and written to a "SavedFigures"
      % folder inside the niceColorbar toolbox folder; session() instead
      % prompts the user for both via a single uiputfile dialog and passes
      % them in explicitly.
      arguments
        obj
        folder {mustBeTextScalar} = ''
        fileName {mustBeTextScalar} = ''
      end
      obj.saveFigureAs('png',folder,fileName);
    end

    function saveAsPDF(obj,folder,fileName)
      % Exports the figure this colorbar is attached to as a vector PDF.
      % See saveAsPNG() for the folder/fileName arguments' behavior.
      arguments
        obj
        folder {mustBeTextScalar} = ''
        fileName {mustBeTextScalar} = ''
      end
      obj.saveFigureAs('pdf',folder,fileName);
    end

    function saveAsFIG(obj,folder,fileName)
      % Saves the figure this colorbar is attached to as an editable
      % MATLAB .fig file. See saveAsPNG() for the folder/fileName
      % arguments' behavior.
      arguments
        obj
        folder {mustBeTextScalar} = ''
        fileName {mustBeTextScalar} = ''
      end
      obj.saveFigureAs('fig',folder,fileName);
    end

  end

  methods (Access = public, Static)

    function session()
      % Interactive command-line loop for adjusting colorbar limits from
      % the MATLAB console without writing throwaway script code. Commands
      % operate on whichever figure currently has focus (per
      % groot().CurrentFigure) at the moment each command is entered - since
      % MATLAB still services figure-click/focus events while input() waits
      % on the keyboard, clicking a different figure mid-session (e.g.
      % switching from Figure2 to Figure3) redirects subsequent commands to
      % that figure's own niceColorbar instance, no re-invocation needed.
      disp('niceColorbar interactive session.');
      disp('Click a figure to target it, then enter a command below.');
      niceColorbar.printSessionCommands();
      keepRunning = true;
      while keepRunning
        txt = strtrim(input('niceColorbar> ','s'));
        switch txt
          case {'help','?'}
            niceColorbar.printSessionCommands();
          case 'limits'
            obj = niceColorbar.currentInstance();
            if isempty(obj)
              disp('No niceColorbar is registered on the current figure.');
              continue
            end
            maxVal = readNumberPrompt('  -> Enter max. value: ');
            minVal = readNumberPrompt('  -> Enter min. value: ');
            if isnan(maxVal) || isnan(minVal)
              disp('Could not set limits: value must be a number');
              continue
            end
            try
              obj.setLimits([minVal maxVal]);
            catch ME
              disp(['Could not set limits: ',ME.message]);
            end
          case 'limits.capped'
            obj = niceColorbar.currentInstance();
            if isempty(obj)
              disp('No niceColorbar is registered on the current figure.');
              continue
            end
            maxVal = readNumberPrompt('  -> Enter max. value: ');
            minVal = readNumberPrompt('  -> Enter min. value: ');
            if isnan(maxVal) || isnan(minVal)
              disp('Could not set capped limits: value must be a number');
              continue
            end
            try
              obj.setCappedLimits([minVal maxVal]);
            catch ME
              disp(['Could not set capped limits: ',ME.message]);
            end
          case 'limits.reset'
            obj = niceColorbar.currentInstance();
            if isempty(obj)
              disp('No niceColorbar is registered on the current figure.');
              continue
            end
            obj.resetLimits();
          case 'style'
            obj = niceColorbar.currentInstance();
            if isempty(obj)
              disp('No niceColorbar is registered on the current figure.');
              continue
            end
            styleTxt = strtrim(input('  -> Enter style: ','s'));
            try
              obj.Style = styleTxt; % setter validates and auto-refreshes the live colorbar
            catch ME
              disp(['Could not set style: ',ME.message]);
            end
          case 'colors'
            obj = niceColorbar.currentInstance();
            if isempty(obj)
              disp('No niceColorbar is registered on the current figure.');
              continue
            end
            numColorsVal = readNumberPrompt('  -> Enter number of colors: ');
            if isnan(numColorsVal)
              disp('Could not set number of colors: value must be a number');
              continue
            end
            try
              obj.NumColormapColors = numColorsVal; % setter validates and auto-refreshes the live colorbar
            catch ME
              disp(['Could not set number of colors: ',ME.message]);
            end
          case 'colormap'
            obj = niceColorbar.currentInstance();
            if isempty(obj)
              disp('No niceColorbar is registered on the current figure.');
              continue
            end
            colormapTxt = strtrim(input('  -> Enter colormap: ','s'));
            try
              obj.ColormapName = colormapTxt; % setter validates and auto-refreshes the live colorbar
            catch ME
              disp(['Could not set colormap: ',ME.message]);
            end
          case 'dark'
            list = niceColorbar.instancesOnCurrentFigure();
            if isempty(list)
              disp('No niceColorbar is registered on the current figure.');
              continue
            end
            for i = 1:numel(list)
              list{i}.ThemeMode = 'dark';
            end
          case 'light'
            list = niceColorbar.instancesOnCurrentFigure();
            if isempty(list)
              disp('No niceColorbar is registered on the current figure.');
              continue
            end
            for i = 1:numel(list)
              list{i}.ThemeMode = 'light';
            end
          case 'autoscale.on'
            obj = niceColorbar.currentInstance();
            if isempty(obj)
              disp('No niceColorbar is registered on the current figure.');
              continue
            end
            decimalsVal = readNumberPrompt('  -> Enter number of decimals (blank = 2): ');
            if isnan(decimalsVal)
              decimalsVal = 2; % default when the user just presses Enter
            end
            try
              obj.TickLabelsAutoScaleDecimals = decimalsVal; % setter validates and auto-refreshes the live colorbar
            catch ME
              disp(['Could not set number of decimals: ',ME.message]);
              continue
            end
            obj.TickLabelsAutoScale = true; % setter validates and auto-refreshes the live colorbar
          case 'autoscale.off'
            obj = niceColorbar.currentInstance();
            if isempty(obj)
              disp('No niceColorbar is registered on the current figure.');
              continue
            end
            obj.TickLabelsAutoScale = false; % setter validates and auto-refreshes the live colorbar
          case 'hide.colorbar'
            obj = niceColorbar.currentInstance();
            if isempty(obj)
              disp('No niceColorbar is registered on the current figure.');
              continue
            end
            obj.ColorbarVisible = 'off'; % setter validates and auto-refreshes the live colorbar
          case 'show.colorbar'
            obj = niceColorbar.currentInstance();
            if isempty(obj)
              disp('No niceColorbar is registered on the current figure.');
              continue
            end
            obj.ColorbarVisible = 'on'; % setter validates and auto-refreshes the live colorbar
          case 'hide.title'
            obj = niceColorbar.currentInstance();
            if isempty(obj)
              disp('No niceColorbar is registered on the current figure.');
              continue
            end
            obj.TitleVisible = 'off'; % setter validates and auto-refreshes the live colorbar
          case 'show.title'
            obj = niceColorbar.currentInstance();
            if isempty(obj)
              disp('No niceColorbar is registered on the current figure.');
              continue
            end
            obj.TitleVisible = 'on'; % setter validates and auto-refreshes the live colorbar
          case 'hide.logo'
            obj = niceColorbar.currentInstance();
            if isempty(obj)
              disp('No niceColorbar is registered on the current figure.');
              continue
            end
            obj.LogoVisible = 'off'; % setter validates and auto-refreshes the live colorbar
          case 'show.logo'
            obj = niceColorbar.currentInstance();
            if isempty(obj)
              disp('No niceColorbar is registered on the current figure.');
              continue
            end
            obj.LogoVisible = 'on'; % setter validates and auto-refreshes the live colorbar
          case 'hide.all'
            obj = niceColorbar.currentInstance();
            if isempty(obj)
              disp('No niceColorbar is registered on the current figure.');
              continue
            end
            obj.SuspendRefresh = true;
            obj.ColorbarVisible = 'off';
            obj.TitleVisible = 'off';
            obj.LogoVisible = 'off';
            obj.SuspendRefresh = false;
            obj.refresh();
          case 'show.all'
            obj = niceColorbar.currentInstance();
            if isempty(obj)
              disp('No niceColorbar is registered on the current figure.');
              continue
            end
            obj.SuspendRefresh = true;
            obj.ColorbarVisible = 'on';
            obj.TitleVisible = 'on';
            obj.LogoVisible = 'on';
            obj.SuspendRefresh = false;
            obj.refresh();
          case 'side.left'
            obj = niceColorbar.currentInstance();
            if isempty(obj)
              disp('No niceColorbar is registered on the current figure.');
              continue
            end
            obj.Side = 'left'; % setter validates and auto-refreshes the live colorbar
          case 'side.right'
            obj = niceColorbar.currentInstance();
            if isempty(obj)
              disp('No niceColorbar is registered on the current figure.');
              continue
            end
            obj.Side = 'right'; % setter validates and auto-refreshes the live colorbar
          case 'side.top'
            obj = niceColorbar.currentInstance();
            if isempty(obj)
              disp('No niceColorbar is registered on the current figure.');
              continue
            end
            obj.Side = 'top'; % setter validates and auto-refreshes the live colorbar
          case 'side.bottom'
            obj = niceColorbar.currentInstance();
            if isempty(obj)
              disp('No niceColorbar is registered on the current figure.');
              continue
            end
            obj.Side = 'bottom'; % setter validates and auto-refreshes the live colorbar
          case 'save.png'
            obj = niceColorbar.currentInstance();
            if isempty(obj)
              disp('No niceColorbar is registered on the current figure.');
              continue
            end
            resolutionVal = readNumberPrompt('  -> Enter export resolution in DPI (blank = 300): ');
            if isnan(resolutionVal)
              resolutionVal = 300; % default when the user just presses Enter
            end
            try
              obj.ExportResolution = resolutionVal; % setter validates and auto-refreshes the live colorbar
            catch ME
              disp(['Could not set export resolution: ',ME.message]);
              continue
            end
            [fileName,folder] = uiputfile('*.png','Save PNG as','figure.png');
            if isequal(fileName,0)
              disp('Save cancelled.');
              continue
            end
            try
              obj.saveAsPNG(folder,fileName);
            catch ME
              disp(['Could not save PNG: ',ME.message]);
            end
          case 'save.pdf'
            obj = niceColorbar.currentInstance();
            if isempty(obj)
              disp('No niceColorbar is registered on the current figure.');
              continue
            end
            renderTxt = strtrim(input('  -> Enter render type: vector/image (blank = image): ','s'));
            if isempty(renderTxt)
              renderTxt = 'image'; % default when the user just presses Enter
            end
            try
              obj.PdfRender = renderTxt; % setter validates and auto-refreshes the live colorbar
            catch ME
              disp(['Could not set render type: ',ME.message]);
              continue
            end
            if obj.PdfRender == "image"
              resolutionVal = readNumberPrompt('  -> Enter export resolution in DPI (blank = 300): ');
              if isnan(resolutionVal)
                resolutionVal = 300; % default when the user just presses Enter
              end
              try
                obj.ExportResolution = resolutionVal; % setter validates and auto-refreshes the live colorbar
              catch ME
                disp(['Could not set export resolution: ',ME.message]);
                continue
              end
            end
            [fileName,folder] = uiputfile('*.pdf','Save PDF as','figure.pdf');
            if isequal(fileName,0)
              disp('Save cancelled.');
              continue
            end
            try
              obj.saveAsPDF(folder,fileName);
            catch ME
              disp(['Could not save PDF: ',ME.message]);
            end
          case 'save.fig'
            obj = niceColorbar.currentInstance();
            if isempty(obj)
              disp('No niceColorbar is registered on the current figure.');
              continue
            end
            [fileName,folder] = uiputfile('*.fig','Save FIG as','figure.fig');
            if isequal(fileName,0)
              disp('Save cancelled.');
              continue
            end
            try
              obj.saveAsFIG(folder,fileName);
            catch ME
              disp(['Could not save FIG: ',ME.message]);
            end
          case 'exit'
            keepRunning = false;
            disp('Plotting session terminated by the user.');
          otherwise
            disp('Command not available. Type ''help'' to see the list of commands.');
        end
      end
    end

  end

  methods (Access = private, Static)

    function printSessionCommands()
      % wrapCommaList actually breaks this onto multiple printed lines (at
      % most 100 columns each); string concatenation with '...' line
      % continuations does not - it just builds one long line that looks
      % broken up in the source but prints as a single wide line.
      commands = {'help','limits','limits.capped','limits.reset','style','colors','colormap', ...
                  'dark','light','autoscale.on','autoscale.off','hide.colorbar','show.colorbar', ...
                  'hide.title','show.title','hide.logo','show.logo','hide.all','show.all', ...
                  'side.left','side.right','side.top','side.bottom','save.png','save.pdf', ...
                  'save.fig','exit'};
      fprintf('Commands:\n%s\n',wrapCommaList(commands,100));
    end

    function out = resizeHub(action,fig,obj)
      % Per-figure registry of niceColorbar instances, keyed by figure
      % handle. This is what lets multiple colorbars share one figure
      % (e.g. one per subplot): each instance registers itself here
      % instead of overwriting obj.fig.SizeChangedFcn directly, and a
      % single shared callback dispatches to every still-valid instance
      % registered against that figure. Being a Static method (rather than
      % a plain local function) lets it call the private onResize() on any
      % instance, not just the one that happens to own the call.
      %
      % (Interactive 3-D rotation is handled separately, via a per-axes
      % View listener set up in colorbar() - see that listener's comment
      % for why: unlike a plain window resize, which always fires
      % SizeChangedFcn, rotate3d's ActionPostCallback was tried here first
      % and found not to reliably fire for the modern axes-toolbar Rotate
      % interaction, so it isn't used.)
      persistent registry
      if isempty(registry)
        registry = containers.Map('KeyType','double','ValueType','any');
      end
      key = double(fig);
      switch action
        case 'register'
          if isKey(registry,key)
            list = registry(key);
            keep = true(size(list));
            for i = 1:numel(list)
              h = list{i};
              if ~isvalid(h)
                keep(i) = false;
              elseif h == obj || isequal(h.ax,obj.ax)
                % h==obj: re-registering this same instance (e.g.
                % colorbar() called again to rebind to a new axes).
                % isequal(h.ax,obj.ax): a DIFFERENT, now-orphaned
                % niceColorbar instance still wraps this very same axes -
                % e.g. a script re-run (without a full close all/clear)
                % that reuses the same figure/axes and builds a fresh
                % niceColorbar on it, leaving the old object with no
                % remaining variable reference in the user's workspace
                % but kept alive forever anyway by its own
                % SettleTimer/ResizePollTimer closures (a handle-class
                % self-reference cycle - confirmed via timerfindall
                % showing timer pairs accumulating well beyond the number
                % of live figures after repeated re-runs). Stop/delete
                % its timers so it can actually be garbage collected
                % instead of continuing to fight the new instance for
                % control of the same Title/Logo/colorbar objects -
                % exactly the overlapping/garbled rendering this was
                % reported to cause.
                if h ~= obj
                  h.cancelSettleRefresh();
                end
                keep(i) = false;
              end
            end
            list = list(keep);
          else
            list = {};
          end
          list{end+1} = obj;
          registry(key) = list;
        case 'dispatch'
          if isKey(registry,key)
            list = registry(key);
            list = list(cellfun(@isvalid,list));
            if isempty(list)
              remove(registry,key);
            else
              registry(key) = list;
              for i = 1:numel(list)
                list{i}.onResize();
              end
            end
          end
        case 'get'
          % returns the list of still-valid niceColorbar instances
          % registered against fig, without mutating the registry - used by
          % currentInstance() to find which object session() should target
          if isKey(registry,key)
            list = registry(key);
            list = list(cellfun(@isvalid,list));
          else
            list = {};
          end
          out = list;
        otherwise
          % action is always one of 'register'/'dispatch'/'get', all called
          % internally from this file - no other value is ever passed
          error('niceColorbar:resizeHub:invalidAction','unknown action ''%s''',action);
      end
    end

    function sharedPollTimer(action)
      % ONE timer shared by every live niceColorbar instance - the watchdog
      % that catches figure resizes SizeChangedFcn misses entirely (see
      % colorbar()'s comment on why this exists at all). Replaces an
      % earlier one-timer-per-instance design: reuses resizeHub's own
      % per-figure registry rather than keeping a second list in sync, so
      % every registered instance (across every open figure) gets checked
      % in a single sweep per tick instead of N independent timers each
      % reacting to the same external event on their own schedule.
      persistent t
      switch action
        case 'ensure'
          % idempotent - safe to call from every colorbar() build
          if isempty(t) || ~isvalid(t)
            t = timer('ExecutionMode','fixedRate','Period',1, ...
              'TimerFcn',@(~,~) niceColorbar.sharedPollTimer('tick'));
          end
          if strcmp(t.Running,'off')
            start(t);
          end
        case 'tick'
          figs = findall(groot,'Type','figure');
          for i = 1:numel(figs)
            fig = figs(i);
            % cheap skip: the toolstrip "maximize figure" gap this exists
            % to catch can only ever happen on a figure the user can
            % actually see - and most figures in a full test-suite run
            % are Visible='off', so this keeps their cost near zero
            if ~isvalid(fig) || ~strcmp(fig.Visible,'on')
              continue
            end
            list = niceColorbar.resizeHub('get',fig);
            for j = 1:numel(list)
              list{j}.pollForMissedResize();
            end
          end
        otherwise
          error('niceColorbar:sharedPollTimer:invalidAction','unknown action ''%s''',action);
      end
    end

    function obj = currentInstance()
      % Resolves which niceColorbar instance session() should act on: the
      % one registered against whichever figure currently has focus (per
      % groot().CurrentFigure - unlike gcf, this never creates a new figure
      % just by being queried). If that figure hosts more than one
      % niceColorbar (e.g. one per subplot), prefer the one whose axes
      % matches the figure's CurrentAxes.
      obj = [];
      fig = get(groot,'CurrentFigure');
      if isempty(fig) || ~isvalid(fig)
        return
      end
      list = niceColorbar.resizeHub('get',fig);
      if isempty(list)
        return
      end
      curAx = get(fig,'CurrentAxes');
      if numel(list) > 1 && ~isempty(curAx)
        idx = find(cellfun(@(o) isequal(o.ax,curAx), list),1);
        if ~isempty(idx)
          obj = list{idx};
          return
        end
      end
      obj = list{1};
    end

    function list = instancesOnCurrentFigure()
      % All still-valid niceColorbar instances registered against whichever
      % figure currently has focus (per groot().CurrentFigure). Unlike
      % currentInstance() - which picks the single instance matching the
      % focused axes, for commands like limits/style that should only touch
      % one subplot - this returns every instance on the figure, since
      % ThemeMode changes obj.fig.Color (shared by every axes on that
      % figure): applying it to only one instance would leave sibling
      % subplots' axes/colorbar colors out of sync with the new background.
      list = {};
      fig = get(groot,'CurrentFigure');
      if isempty(fig) || ~isvalid(fig)
        return
      end
      list = niceColorbar.resizeHub('get',fig);
    end

  end

  methods (Access = private)

    function filePath = saveFigureAs(obj,format,folder,fileName)
      % Shared implementation behind saveAsPNG()/saveAsPDF(). folder = ''
      % and fileName = '' (the defaults from both public methods) resolve
      % to an auto-generated name (figure number + timestamp) written to a
      % "SavedFigures" folder inside the niceColorbar toolbox folder, so
      % scripted calls (examples.m) always land somewhere predictable
      % relative to the toolbox; session() instead resolves both via a
      % single uiputfile dialog and passes them in explicitly, so the two
      % call sites share every line of export logic below.
      if ~obj.Built || isempty(obj.fig) || ~isvalid(obj.fig)
        error('niceColorbar:saveFigureAs:notBuilt','colorbar() must be called before saving the figure');
      end
      if isempty(folder)
        folder = fullfile(fileparts(mfilename('fullpath')),'SavedFigures');
      end
      if ~isfolder(folder)
        mkdir(folder);
      end
      if isempty(fileName)
        timestamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
        fileName = sprintf('niceColorbar_fig%d_%s',obj.fig.Number,timestamp);
      else
        % drop whatever extension the caller may have already typed (e.g.
        % 'plot.png', or 'plot.jpg' if uiputfile's automatic "All Files"
        % entry was picked with a different/no extension) - the format this
        % method was called with is what actually gets written, always
        % re-appended below, regardless of what the dialog returned
        [~,fileName] = fileparts(fileName);
      end
      filePath = fullfile(folder,sprintf('%s.%s',fileName,format));
      % raise obj.fig to the front and flush pending graphics updates
      % before exporting - a docked figure that isn't the active tab (or
      % one with a resize/property change still pending) can otherwise
      % export a stale or incomplete frame, capturing only whichever
      % subplot/tab last happened to render. drawnow alone isn't always
      % enough for a just-raised docked tab to finish repainting, so give
      % it a brief moment before exportgraphics reads back the frame.
      figure(obj.fig);
      drawnow;
      pause(0.2);
      switch format
        case 'png'
          exportgraphics(obj.fig,filePath,'Resolution',obj.ExportResolution);
        case 'pdf'
          if obj.PdfRender == "vector"
            % exportgraphics warns every time vector content is requested
            % ("Vectorized content might take a long time...") - expected
            % and harmless given the user explicitly opted into 'vector',
            % so silence just this one warning ID for the call rather than
            % leaving it to spam the console on every save.
            warnState = warning('off','MATLAB:print:ContentTypeImageSuggested');
            cleanupWarn = onCleanup(@() warning(warnState));
            exportgraphics(obj.fig,filePath,'ContentType','vector');
          else
            exportgraphics(obj.fig,filePath,'ContentType','image','Resolution',obj.ExportResolution);
          end
        case 'fig'
          % savefig(), not exportgraphics() - .fig is MATLAB's own editable
          % figure format, not a rendered image/vector export
          savefig(obj.fig,filePath);
        otherwise
          % format is always 'png', 'pdf', or 'fig', passed internally by
          % saveAsPNG()/saveAsPDF()/saveAsFIG() - no other value is ever passed
          error('niceColorbar:saveFigureAs:invalidFormat','unknown format ''%s''',format);
      end
      fprintf('niceColorbar: saved %s\n',filePath);
    end

    function refresh(obj)
      % PostSet callback shared by every public property. Guarded so that
      % (a) property assignments made before the first colorbar() call -
      % e.g. inside the constructor - are silently ignored, since there's
      % no live colorbar to update yet, and (b) nothing errors if the
      % colorbar/figure was closed out from under the object.
      if obj.SuspendRefresh || ~obj.Built || isempty(obj.clb) || ~isvalid(obj.clb)
        return;
      end
      obj.applyProperties();
    end

    function resolveTheme(obj)
      % Resolves obj.ThemeBgColor/obj.ThemeFontColor and applies them to
      % the figure/axes. 'auto' (the default) detects MATLAB's live
      % light/dark mode; 'light'/'dark' force that look regardless of what
      % MATLAB is actually using. Called once from colorbar() at build time
      % and again from applyProperties() on every refresh, so toggling
      % ThemeMode after the colorbar is already built takes effect right
      % away through the normal auto-refresh mechanism, like any other
      % property.
      switch obj.ThemeMode
        case 'dark'
          useDark = true;
        case 'light'
          useDark = false;
        otherwise % 'auto'
          useDark = isMatlabDarkMode(obj.fig);
      end
      if useDark
        obj.ThemeBgColor = [0.15 0.15 0.15];
        obj.ThemeFontColor = [1 1 1];
      else
        obj.ThemeBgColor = [1 1 1];
        obj.ThemeFontColor = [0 0 0];
      end
      obj.fig.Color = obj.ThemeBgColor;
      obj.ax.Color = obj.ThemeBgColor;
      obj.ax.XColor = obj.ThemeFontColor;
      obj.ax.YColor = obj.ThemeFontColor;
      obj.ax.ZColor = obj.ThemeFontColor;
    end

    function applyProperties(obj)
      % Re-applies every cosmetic/layout-affecting property to the live
      % colorbar. This is the "cold path" - it runs once on build and
      % again on every user-driven property change, but deliberately never
      % on plain figure resize (see onResize/updateColorbarLayout and the
      % original perf comments on setColorbarLevels below): recomputing
      % the colormap and tick labels on every resize tick is what used to
      % cause drag-time lag.
      obj.resolveTheme();
      styleParams = getStyleParams();
      if ~isKey(styleParams,obj.Style)
        error('niceColorbar:colorbar:styleNotAvailable','colorbar style not available!');
      end
      cfg = styleParams(obj.Style);
      layout.scale      = cfg.scale;      % fraction of true plotting axis height
      layout.pixelGap   = cfg.pixelGap;   % pixels off the right graphic boundary
      layout.pixelWidth = cfg.pixelWidth; % pixels thickness wide
      hideTicksAndBox   = cfg.hideTicksAndBox;
      obj.ResizeLayout  = layout; % cached so onResize() stays in sync with Style

      %% side: which side of the plot the colorbar sits on
      % Location drives which side of the bar MATLAB renders its ticks on
      % (AxisLocation auto-follows Location: 'out' for both 'eastoutside'
      % and 'westoutside', i.e. always the side facing away from the plot).
      % updateColorbarLayout() below positions the bar itself via explicit
      % pixel Position, which is independent of Location - both need to
      % agree on the side, or the ticks end up sandwiched between the bar
      % and the plot instead of facing away from it.
      switch obj.Side
        case "left"
          obj.clb.Location = 'westoutside';
        case "top"
          obj.clb.Location = 'northoutside';
        case "bottom"
          obj.clb.Location = 'southoutside';
        otherwise % "right"
          obj.clb.Location = 'eastoutside';
      end

      %% tick cosmetics
      set(obj.clb,'FontName',obj.TickLabelsFontName,'FontSize',obj.TickLabelsFontSize,...
                  'FontWeight',obj.TickLabelsFontWeight,'LineWidth',obj.TickLineWidth,...
                  'Color',obj.TickLineColor);

      %% colorbar title properties
      % normalize Title into a cellstr of lines regardless of whether the
      % user assigned a char, string, or cell array
      if iscell(obj.Title)
        titleLines = obj.Title;
      elseif isstring(obj.Title) && ~isscalar(obj.Title)
        titleLines = cellstr(obj.Title);
      else
        titleLines = {char(obj.Title)};
      end

      % TickLabelsAutoScale: auto-derive a power-of-10 exponent from the
      % actual data range (like MATLAB's classic axis exponent behavior).
      % Computed here (needed below for tick-label scaling too, and passed
      % into setColorbarLevels/setCappedColorbarLevels so both agree); the
      % "x10^n" annotation itself is built as its own standalone object
      % further down (see obj.ExpLabelObj), entirely separate from
      % Title/TitleLineObjs - it must never consume or renumber the user's
      % own Title lines.
      if obj.TickLabelsAutoScale
        if obj.Capped
          expN = autoScaleExponent(obj.CappedLimits);
        else
          expN = autoScaleExponent(clim(obj.ax));
        end
      else
        expN = 0;
      end

      % A 3-D axes' own Z ruler autoscales in lockstep with the colorbar:
      % same expN (derived from the colorbar's own limits above), reusing
      % MATLAB's native NumericRuler Exponent/ExponentMode instead of
      % hand-rolling tick-label text, since ZAxis already supports exactly
      % this. Reverting to 'auto' when off (or when expN comes out 0) hands
      % control back to MATLAB's own default exponent heuristic rather than
      % leaving it pinned at whatever manual value was last set.
      if isAxes3D(obj.ax)
        if obj.TickLabelsAutoScale && expN ~= 0
          obj.ax.ZAxis.Exponent = expN;
          % keep the Z tick labels' own decimal count in lockstep with the
          % colorbar's TickLabelsAutoScaleDecimals, same '%+.<n>f' format
          % the colorbar itself uses (see setColorbarLevels) - otherwise
          % the two rulers can disagree on how many digits they show even
          % though they share the same exponent.
          obj.ax.ZAxis.TickLabelFormat = sprintf('%%+.%df',obj.TickLabelsAutoScaleDecimals);
          % SecondaryLabel is the ruler's actual "x10^n" text object. Its
          % Position can't be nudged directly: writing it even once
          % permanently disables MATLAB's own adaptive camera-tracking
          % placement for that object (verified empirically - no amount of
          % toggling ExponentMode/Visible/Exponent afterward restores it).
          % So it's hidden and mirrored with a standalone text (ZExpLabelObj)
          % instead, positioned from the native label's still-live Position
          % each call.
          nativeExpLabel = obj.ax.ZAxis.SecondaryLabel;
          nativeExpLabel.FontSize = obj.ax.ZAxis.FontSize + 2; % same +2-over-labels
                                                               % rule the colorbar's
                                                               % own ExpLabelObj follows
          % MATLAB stops updating a Text object's screen transform while
          % it's hidden, so leaving Visible='off' from a previous call and
          % reading Position in 'pixels' straight away returns a stale
          % (badly wrong after any further rotation) value - flip it
          % visible and force one render first to get an up-to-date read,
          % then hide it again once basePos is captured. Kept in 'pixels'
          % throughout (never converted back to 'data'), same as
          % ExpLabelObj/Title lines elsewhere in this method: interactive
          % rotation alone never re-runs applyProperties anyway (only an
          % actual property change does - see onViewChanged/onSettleRefresh,
          % which only re-run the cheap/accurate LAYOUT pass), so there is
          % no live camera-tracking to gain from 'data' units here, only a
          % fragile pixel<->data round-trip to lose - it produced wildly
          % out-of-range positions in practice (verified: a stale 'data'
          % conversion once read back as thousands of units outside the
          % axes' actual data range).
          nativeExpLabel.Visible = 'on';
          drawnow;
          nativeExpLabel.Units = 'pixels';
          basePos = nativeExpLabel.Position;
          nativeExpLabel.Visible = 'off';
          nativeExpLabel.Units = 'data'; % restore native's own Units so nothing
                                          % about it looks altered besides Visible
          if isempty(obj.ZExpLabelObj) || ~isvalid(obj.ZExpLabelObj)
            obj.ZExpLabelObj = text(obj.ax,0,0,0,'','Units','pixels', ...
              'XLimInclude','off','YLimInclude','off','ZLimInclude','off');
          end
          obj.ZExpLabelObj.Units = 'pixels';
          obj.ZExpLabelObj.String = nativeExpLabel.String;
          obj.ZExpLabelObj.Interpreter = nativeExpLabel.Interpreter;
          obj.ZExpLabelObj.FontName = nativeExpLabel.FontName;
          obj.ZExpLabelObj.FontSize = nativeExpLabel.FontSize;
          obj.ZExpLabelObj.FontWeight = nativeExpLabel.FontWeight;
          obj.ZExpLabelObj.Color = nativeExpLabel.Color;
          obj.ZExpLabelObj.HorizontalAlignment = nativeExpLabel.HorizontalAlignment;
          obj.ZExpLabelObj.VerticalAlignment = nativeExpLabel.VerticalAlignment;
          obj.ZExpLabelObj.Position = basePos + [0 0 0]; % use middle position of the square 
                                                         % bracket to move up/down the exponent 
                                                         % of the Z-axis (coordinates in
                                                         % the square bracket is in the
                                                         % pixel coordinate system, which
                                                         % is a 2D system (third entry is
                                                         % ignored)
        else
          obj.ax.ZAxis.ExponentMode = 'auto';
          obj.ax.ZAxis.TickLabelFormat = '%g';
          if ~isempty(obj.ax.ZAxis.SecondaryLabel)
            obj.ax.ZAxis.SecondaryLabel.Visible = 'on';
          end
          if ~isempty(obj.ZExpLabelObj) && isvalid(obj.ZExpLabelObj)
            delete(obj.ZExpLabelObj);
            obj.ZExpLabelObj = [];
          end
        end
      end

      % Every line always renders as its own standalone text object
      % parented to obj.ax (never through the colorbar's native Title),
      % regardless of whether TitleColor is per-line (a cell) or a single
      % uniform color ([] or one explicit color/theme-follow spec applied
      % to every line): a colorbar's native Title, unlike an axes Title,
      % visually disappears along with the colorbar when ColorbarVisible
      % is 'off' despite its own Visible property staying 'on' - so
      % keeping Title genuinely independent of ColorbarVisible requires it
      % to never be the colorbar's own child in the first place.
      obj.clb.Title.String = ''; % blank the native Title; lines render via TitleLineObjs
      use3DOverlay = isAxes3D(obj.ax);
      for i = 1:numel(titleLines)
        if i <= numel(obj.TitleLineObjs) && isvalid(obj.TitleLineObjs{i})
          h = obj.TitleLineObjs{i};
        elseif use3DOverlay
          % A 3-D axes re-projects an axes-child 'pixels'-unit text's
          % stored Position on every camera change (rotate/pan), even with
          % no Position write of ours in between - confirmed by rotating
          % the view and finding the SAME stored Position rendering at a
          % different screen location. A figure-level annotation textbox
          % has no such camera dependency, so it stays exactly where last
          % placed regardless of how the user rotates/pans the 3-D view
          % afterward - text() can't parent to a figure directly, hence
          % annotation('textbox',...) instead, only for a 3-D axes (a 2-D
          % axes' child text has no such issue - see updateColorbarLayout).
          h = annotation(obj.fig,'textbox',[0 0 0.01 0.01],'Units','pixels', ...
                'EdgeColor','none','LineStyle','none','FitBoxToText','on','Margin',0);
          obj.TitleLineObjs{i} = h;
        else
          h = text(obj.ax,0,0,'','Units','pixels');
          % keep this overlay text from ever nudging obj.ax's data limits
          % (it's positioned in pixels above the colorbar, not tied to any
          % data point)
          h.XLimInclude = 'off';
          h.YLimInclude = 'off';
          h.ZLimInclude = 'off';
          obj.TitleLineObjs{i} = h;
        end
        h.String = titleLines{i};
        h.Interpreter = obj.TitleInterpreter;
        h.FontName = obj.TitleFontName;
        h.FontSize = obj.TitleFontSize;
        h.FontWeight = obj.TitleFontWeight;
        if iscell(obj.TitleColor)
          % per-line: TitleColor{i} colors titleLines{i} ([] entry -> auto-follow the theme for that line)
          if i <= numel(obj.TitleColor) && ~isempty(obj.TitleColor{i})
            h.Color = obj.TitleColor{i};
          else
            h.Color = obj.ThemeFontColor;
          end
        elseif isempty(obj.TitleColor)
          % user never declared a TitleColor -> every line follows the current theme
          h.Color = obj.ThemeFontColor;
        else
          % user declared a single explicit color -> every line honors it, regardless of theme
          h.Color = obj.TitleColor;
        end
      end
      % drop leftover line objects from a previous, longer Title
      for i = numel(titleLines)+1:numel(obj.TitleLineObjs)
        if isvalid(obj.TitleLineObjs{i}); delete(obj.TitleLineObjs{i}); end
      end
      obj.TitleLineObjs(numel(titleLines)+1:end) = [];

      %% create / update / remove the logo
      % Parented to obj.ax (like TitleLineObjs above), not to obj.clb - a
      % colorbar's native Label/ylabel is tied to the axis ruler and goes
      % invisible along with the colorbar itself, which would make
      % LogoVisible impossible to keep independent of ColorbarVisible; a
      % standalone text object has no such coupling.
      if ~isempty(obj.Logo)
        if isempty(obj.ylb) || ~isvalid(obj.ylb)
          if use3DOverlay
            % see the matching TitleLineObjs branch above for why a 3-D
            % axes needs a figure-level annotation instead of an axes-child
            % text here
            obj.ylb = annotation(obj.fig,'textbox',[0 0 0.01 0.01],'Units','pixels', ...
                'EdgeColor','none','LineStyle','none','FitBoxToText','on','Margin',0);
          else
            obj.ylb = text(obj.ax,0,0,'','Units','pixels');
            % keep this overlay text from ever nudging obj.ax's data limits
            % (it's positioned in pixels below the colorbar, not tied to any
            % data point) - same reasoning as TitleLineObjs above
            obj.ylb.XLimInclude = 'off';
            obj.ylb.YLimInclude = 'off';
            obj.ylb.ZLimInclude = 'off';
          end
        end
        obj.ylb.String = obj.Logo;
        obj.ylb.FontName = obj.LogoFontName;
        obj.ylb.FontSize = obj.LogoFontSize;
        obj.ylb.FontWeight = obj.LogoFontWeight;
        % base color follows the theme; any '\color[rgb]{...}' tag the user
        % embeds directly in the Logo text (per its example comment) still
        % overrides from that point onward, same as it always has - setting
        % this base unconditionally (rather than gating on tag presence)
        % also lets an untagged line in a multi-line Logo fall back to the
        % theme color even when another line carries its own tag
        obj.ylb.Color = obj.ThemeFontColor;
      elseif ~isempty(obj.ylb) && isvalid(obj.ylb)
        % Logo was cleared out (set to {} or '') - remove the leftover label
        delete(obj.ylb);
        obj.ylb = [];
      end

      %% create / update / remove the TickLabelsAutoScale "x10^n" annotation
      % Standalone object, same construction pattern as the Logo (obj.ylb)
      % above - deliberately NOT one of TitleLineObjs, so it never consumes
      % or renumbers the user's own Title lines/TitleColor entries; always
      % theme-follows regardless of TitleColor. Positioned in
      % updateColorbarLayout right above the Title stack (see there).
      if expN ~= 0
        switch obj.TitleInterpreter
          case "latex"
            expStr = sprintf('$\\times10^{%d}$', expN);
          case "tex"
            expStr = sprintf('\\times10^{%d}', expN);
          otherwise
            expStr = sprintf('x10^%d', expN);
        end
        if isempty(obj.ExpLabelObj) || ~isvalid(obj.ExpLabelObj)
          if use3DOverlay
            obj.ExpLabelObj = annotation(obj.fig,'textbox',[0 0 0.01 0.01],'Units','pixels', ...
                'EdgeColor','none','LineStyle','none','FitBoxToText','on','Margin',0);
          else
            obj.ExpLabelObj = text(obj.ax,0,0,'','Units','pixels');
            obj.ExpLabelObj.XLimInclude = 'off';
            obj.ExpLabelObj.YLimInclude = 'off';
            obj.ExpLabelObj.ZLimInclude = 'off';
          end
        end
        obj.ExpLabelObj.String = expStr;
        obj.ExpLabelObj.Interpreter = obj.TitleInterpreter;
        % follows the tick labels' own font (it's conceptually part of the
        % tick-label column, not the Title), a couple points larger so it
        % still reads as a small header above them rather than blending in
        obj.ExpLabelObj.FontName = obj.TickLabelsFontName;
        obj.ExpLabelObj.FontSize = obj.TickLabelsFontSize + 2;
        obj.ExpLabelObj.FontWeight = 'normal';
        obj.ExpLabelObj.Color = obj.ThemeFontColor;
      elseif ~isempty(obj.ExpLabelObj) && isvalid(obj.ExpLabelObj)
        % TickLabelsAutoScale is off, or n came out 0 - remove the leftover label
        delete(obj.ExpLabelObj);
        obj.ExpLabelObj = [];
      end

      if use3DOverlay
        % updateColorbarLayout (called right after this) reads back each
        % annotation textbox's FitBoxToText-fitted [w h] to place it - that
        % resize doesn't resolve synchronously just from setting
        % String/Font above, so force it to settle now rather than
        % positioning against a stale (e.g. near-zero) size. Reassigning
        % obj.clb.Location just above snaps the colorbar back to MATLAB's
        % own default auto full-height layout, which only gets corrected
        % back to the compact custom Position once updateColorbarLayout
        % runs after this - so this forced drawnow would otherwise paint
        % that stretched, wrong-height colorbar overlapping the title/logo
        % for one visible frame. Hiding it for this one render avoids that;
        % its real Visible state is restored unconditionally at the end of
        % this function regardless of what it's set to here.
        obj.clb.Visible = 'off';
        drawnow;
      end

      %% colormap generation and tick-label formatting
      if obj.Capped
        obj.setCappedColorbarLevels(hideTicksAndBox,expN);
      else
        obj.setColorbarLevels(hideTicksAndBox,expN);
      end

      % cache the tick-label extent once here (obj.clb.TickLabels just got
      % populated above) rather than in updateColorbarLayout, which also
      % runs on every plain-resize tick (onResize) - measuring via a
      % throwaway text object on every such tick would reintroduce exactly
      % the per-tick lag the rest of this class works to avoid
      if expN ~= 0
        [w,h] = obj.measureTickLabelExtent();
        obj.TickLabelExtent = [w,h];
      end

      %% pixel layout; iterate a few times to let it settle against
      % MATLAB's own auto-sizing, same as the original build path. A 3-D
      % axes' ax.Position doesn't need this settling (stage 1's dataRatio
      % comes straight from XLim/YLim, not from anything that feeds back on
      % itself across iterations, unlike TightInset for a 2-D axes), and
      % each iteration measures the 3-D content bbox from scratch (several
      % text-object probes) - repeating that 4x over was the main cost
      % behind a multi-second lag after every property change, so only
      % iterate for 2-D, where it's actually needed.
      if use3DOverlay
        obj.updateColorbarLayout(layout,true);
      else
        for i = 1:4
          obj.updateColorbarLayout(layout,true);
        end
      end

      %% per-element visibility - each hides/shows in place without
      % discarding or rebuilding anything, so switching back to 'on'
      % restores that exact element. Both Title (TitleLineObjs) and Logo
      % (obj.ylb) are standalone text objects parented to obj.ax rather
      % than obj.clb (see applyProperties for why - a colorbar's native
      % Title/Label both visually disappear along with the colorbar
      % itself, unlike an axes Title), so toggling obj.clb.Visible here has
      % no bearing on either of them.
      obj.clb.Visible = obj.ColorbarVisible;
      for i = 1:numel(obj.TitleLineObjs)
        if isvalid(obj.TitleLineObjs{i})
          obj.TitleLineObjs{i}.Visible = obj.TitleVisible;
        end
      end
      if ~isempty(obj.ylb) && isvalid(obj.ylb)
        obj.ylb.Visible = obj.LogoVisible;
      end
      if ~isempty(obj.ExpLabelObj) && isvalid(obj.ExpLabelObj)
        % the auto exponent annotation describes the colorbar's own tick
        % scale, not the Title text, so it follows ColorbarVisible (hide
        % only when the colorbar itself is hidden) rather than TitleVisible
        obj.ExpLabelObj.Visible = obj.ColorbarVisible;
      end
    end

    function pollForMissedResize(obj)
      % Called once a second, for every still-registered instance, from
      % the single shared sharedPollTimer (see colorbar()/resizeHub) -
      % NOT from a per-instance timer. Cheaply compares obj.fig's current
      % pixel Position against the last-seen value and, only on an actual
      % difference, runs onResize() exactly as if SizeChangedFcn itself
      % had fired - this exists specifically because it sometimes doesn't
      % (see colorbar()'s comment on this).
      if ~obj.Built || isempty(obj.fig) || ~isvalid(obj.fig) || isempty(obj.clb) || ~isvalid(obj.clb) ...
          || isempty(obj.ax) || ~isvalid(obj.ax)
        return;
      end
      figUnits = obj.fig.Units;
      obj.fig.Units = 'pixels';
      curFigPos = obj.fig.Position;
      obj.fig.Units = figUnits;
      % NOTE: an earlier version of this method also unconditionally forced
      % a repaint nudge here once a second regardless of whether anything
      % changed, as a fallback for container changes (e.g. dragging a whole
      % docked figure group into the Editor's document tab strip) that
      % don't touch obj.fig.Position at all. That was reverted: applying it
      % live produced worse corruption than the bug it was meant to fix
      % (stray leftover Title/Logo/annotation fragments floating
      % mid-canvas on one figure, a squished axes on another) -
      % continuously perturbing clb.Position on every instance, every
      % second, indefinitely, with nothing having actually changed,
      % evidently confuses MATLAB's own docked-tab layout/compositing
      % engine rather than fixing it.
      %
      % obj.ax's own pixel Position is tracked separately from
      % obj.fig.Position because they can drift independently: docking a
      % whole floating figure group into the Editor's document tab strip
      % doesn't change any figure's Position, but a BACKGROUND (not
      % currently the active/selected) docked tab can sit for a while
      % with a stale, not-yet-laid-out obj.ax pixel Position - confirmed
      % live (struct(obj) inspection) on a docked group where 1 of 12
      % niceColorbar instances kept rendering its Title ~87px off after
      % docking, while the other 11 (whichever tab happened to be active
      % at the moment docking settled) came out correct. MATLAB seems to
      % defer laying out a backgrounded tab's contents until it's
      % actually selected, so obj.ax's pixel Position can still change
      % well after obj.fig.Position - and this instance's own
      % SettleTimer poll-until-quiescent already finished by then,
      % reading two consecutive identical (but not yet final) values.
      % Polling ax.Position here too (unlike the reverted unconditional
      % nudge, this only acts on an ACTUAL detected change) catches that
      % once MATLAB finally lays the tab out, self-healing within ~1s.
      axUnits = obj.ax.Units;
      obj.ax.Units = 'pixels';
      curAxPos = obj.ax.Position;
      obj.ax.Units = axUnits;
      figChanged = isempty(obj.LastKnownFigPos) || ~isequal(curFigPos,obj.LastKnownFigPos);
      axChanged = isempty(obj.LastKnownAxPos) || ~isequal(curAxPos,obj.LastKnownAxPos);
      if figChanged || axChanged
        obj.LastKnownFigPos = curFigPos;
        obj.LastKnownAxPos = curAxPos;
        obj.onResize();
      end
    end

    function onResize(obj)
      % SizeChangedFcn hot path. Deliberately does NOT call
      % setColorbarLevels/applyProperties - only the cheap pixel-layout
      % step - since colormap/tick-label generation only depends on
      % NumColormapColors, ColormapName, TickLabelsFormat, and Style, never
      % on the figure's pixel size. obj.ResizeLayout is refreshed by
      % applyProperties() whenever Style (or anything else) changes, so
      % this always reflects the current style even though it's not
      % recomputed here.
      %
      % Also schedules a deferred settle pass (see scheduleSettleRefresh):
      % a single large, instantaneous resize (e.g. maximizing then
      % restoring a docked figure - reported as the colorbar "jumping" far
      % from its correct position) can fire this callback while
      % getPlotboxPixels(obj.ax)'s pixel-unit conversion still reflects the
      % figure's prior size - a graphics-pipeline lag confirmed empirically
      % (immediately reading positions afterward sometimes returned a
      % pixel frame scaled to the OLD, much larger figure; the same
      % sequence sometimes settled correctly on the first callback too -
      % timing-dependent, not deterministic). A normal interactive drag
      % never shows this because it fires many intermediate SizeChangedFcn
      % events that each self-correct the next; a single maximize/restore
      % click does not get that natural follow-up, so one is scheduled
      % here explicitly.
      if ~obj.Built || isempty(obj.clb) || ~isvalid(obj.clb)
        return;
      end
      obj.updateColorbarLayout(obj.ResizeLayout,false);
      obj.scheduleSettleRefresh();
    end

    function onViewChanged(obj)
      % ViewListener's PostSet callback (see colorbar()) - fires on every
      % change to obj.ax's View, including continuously through an
      % interactive rotate drag. Runs the cheap, position-only pass
      % immediately (same one onResize uses - no getframe(), ~1ms scale,
      % measured) so the bar keeps roughly following along without
      % stuttering the drag, then separately schedules the accurate,
      % live-measured pass (see scheduleSettleRefresh) to correct it once
      % rotation settles.
      %
      % Running the accurate pass synchronously on every single View event
      % instead was tried and measured at ~0.26s each - fine for one
      % completed gesture, but reintroduces exactly the kind of per-frame
      % lag this whole hot-path split exists to avoid during an actual
      % drag (which can fire View many times per second). Running only the
      % cheap pass and never following up with an accurate one was also
      % tried and found insufficient on its own: at near-edge-on
      % elevation, the cheap pass's reused gap fraction (obj.Top3DGapFrac,
      % from whatever rotation last had an accurate measurement) can be
      % badly wrong, and if the user stops rotating there, nothing ever
      % corrects it - confirmed as the actual bug reported. Both need to
      % run: cheap now, accurate once settled.
      if ~obj.Built || isempty(obj.clb) || ~isvalid(obj.clb)
        return;
      end
      obj.updateColorbarLayout(obj.ResizeLayout,false);
      obj.scheduleSettleRefresh();
    end

    function scheduleSettleRefresh(obj)
      % Reuses one lazily-created timer object for this instance's entire
      % lifetime (stop+restart on every call, never deleted-and-recreated)
      % rather than constructing a new one per event: an earlier version
      % did the latter and was suspected (though never conclusively proven
      % - see onSettleRefresh) of leaving MATLAB's timer subsystem in a
      % state where new timers stopped firing reliably under heavy load.
      % Reusing the same object was verified, in isolation, to survive 20
      % rapid stop/restart cycles and still fire correctly. Shared by both
      % onResize (settles a stale post-maximize/restore pixel-frame read)
      % and onViewChanged (settles a stale 3-D gap fraction after rotation).
      %
      % Resets the poll-tracking state (see onSettleRefresh) and the timer's
      % delay back to the initial 0.35s: this is called for every new
      % resize/View event, including ones that arrive mid-poll (e.g. a
      % second maximize/restore before the first one finished settling), so
      % the stability check must restart from scratch rather than comparing
      % against a marker from a burst that's no longer relevant.
      obj.SettlePollMarker = [];
      obj.SettlePollCount = 0;
      if isempty(obj.SettleTimer) || ~isvalid(obj.SettleTimer)
        obj.SettleTimer = timer('ExecutionMode','singleShot','StartDelay',0.35, ...
          'TimerFcn',@(~,~) obj.onSettleRefresh());
      else
        if strcmp(obj.SettleTimer.Running,'on')
          stop(obj.SettleTimer);
        end
        obj.SettleTimer.StartDelay = 0.35;
      end
      start(obj.SettleTimer);
    end

    function cancelSettleRefresh(obj)
      % ObjectBeingDestroyed callback (see colorbar()) - stops and deletes
      % this instance's settle timer when its axes closes, rather than
      % leaving it (and its captured reference to obj) dangling. The
      % once-a-second resize poll is no longer a per-instance timer (see
      % sharedPollTimer) so there's nothing else to stop here: the shared
      % timer re-derives its instance list fresh from resizeHub on every
      % tick, which already drops obj once it's no longer valid/registered.
      if ~isempty(obj.SettleTimer) && isvalid(obj.SettleTimer)
        stop(obj.SettleTimer);
        delete(obj.SettleTimer);
      end
      obj.SettleTimer = [];
      obj.SettlePollMarker = [];
      obj.SettlePollCount = 0;
    end

    function onSettleRefresh(obj)
      % Fires ~0.35s after the last resize or View change (see
      % scheduleSettleRefresh), then keeps polling obj.ax's pixel Position
      % every 0.05s until it reads IDENTICAL on two consecutive checks
      % (or a generous cap of retries is hit) before finally taking one
      % accurate, live-measured layout pass - rather than trusting a single
      % fixed-delay check.
      %
      % A single fixed-delay check was tried first and found insufficient:
      % after maximizing then restoring a DOCKED figure's container (one
      % big, instantaneous resize, reported as the colorbar ending up in a
      % wildly wrong position - e.g. hundreds of pixels outside the actual
      % figure), obj.ax's pixel-unit conversion was confirmed, via direct
      % inspection in a live session, to sometimes still be reading a
      % STALE (pre-resize) value even a full 2+ seconds after the resize -
      % a graphics-pipeline lag whose duration isn't fixed or predictable
      % (a plain interactive drag never shows it, since its many
      % intermediate SizeChangedFcn events each naturally self-correct the
      % next one; only a single instantaneous jump lacks that follow-up).
      % Waiting for two consecutive identical reads is a direct test of
      % "has the pipeline actually caught up", independent of how long that
      % takes for any given jump size/monitor configuration.
      %
      % For rotation (unaffected by this lag - obj.ax's pixel Position
      % doesn't depend on View at all), the very first two polls already
      % match, so this still commits promptly (well within the ~0.6s window
      % the rotation-settle tests wait for), just one 0.05s poll interval
      % later than the old single-check version.
      if ~obj.Built || isempty(obj.clb) || ~isvalid(obj.clb)
        obj.SettlePollMarker = [];
        obj.SettlePollCount = 0;
        return;
      end
      oldUnits = obj.ax.Units;
      obj.ax.Units = 'pixels';
      curMarker = obj.ax.Position;
      obj.ax.Units = oldUnits;
      maxPolls = 100; % 0.35s initial + up to 100*0.05s = ~5.35s total cap - well
                     % beyond the worst observed docked maximize/restore lag,
                     % bounded so a pathological case can't poll forever. The
                     % short 0.05s interval keeps the common (already-stable)
                     % case - e.g. rotation, where obj.ax's pixel Position
                     % never depends on View at all - committing at ~0.4s,
                     % comfortably inside the ~0.6s window the rotation-
                     % settle tests wait for.
      stable = ~isempty(obj.SettlePollMarker) && isequal(curMarker,obj.SettlePollMarker);
      if ~stable && obj.SettlePollCount < maxPolls
        obj.SettlePollMarker = curMarker;
        obj.SettlePollCount = obj.SettlePollCount + 1;
        % obj.SettleTimer is still reported Running=='on' for the ENTIRE
        % duration of its own TimerFcn (confirmed empirically - true for
        % the whole callback body, not just after it returns), so it can't
        % be reconfigured/restarted from inside here (MATLAB errors:
        % "StartDelay cannot be set while Timer is running" /
        % "Cannot start timer because it is already running" - discovered
        % the hard way, as a silently-swallowed timer-callback error that
        % left every poll permanently stuck at count 1). Use a short-lived,
        % self-deleting one-off timer instead just for this retry tick;
        % obj.SettleTimer itself is only ever touched from
        % scheduleSettleRefresh, which always runs outside of its own
        % callback.
        retryTimer = timer('ExecutionMode','singleShot','StartDelay',0.05, ...
          'TimerFcn',@(~,~) obj.onSettleRefresh(),'StopFcn',@(src,~) delete(src));
        start(retryTimer);
        return;
      end
      obj.SettlePollMarker = [];
      obj.SettlePollCount = 0;
      obj.updateColorbarLayout(obj.ResizeLayout,true);
      % Setting obj.clb.Position above doesn't always get repainted on
      % screen - confirmed empirically with several docked figures sharing
      % one tabbed container: after a toolstrip maximize on the active tab,
      % clb.Position/Visible/Colormap all read back exactly correct (pixel-
      % verified via getframe()), yet the bar itself stayed blank
      % (background-colored) on screen. Toggling Visible off/on did NOT
      % force a repaint either - only an actual Position VALUE change did.
      % Nudging it by a throwaway pixel and back forces MATLAB to flush that
      % one graphics object rather than trusting the earlier property write
      % to have been painted.
      % Uses 'limitrate' rather than a plain drawnow: with several
      % niceColorbar instances (one per docked figure) settling at roughly
      % the same moment - e.g. every tab in a docked group reacting to one
      % dock/undock action together - a plain drawnow from each instance
      % forces its own full, synchronous flush of every open figure, and
      % those flushes stack up into the multi-second "MATLAB Busy" freeze
      % this was confirmed to cause with 8 docked figures. 'limitrate' still
      % delivers the repaint this nudge exists for, but lets MATLAB coalesce
      % near-simultaneous requests from multiple instances into far fewer
      % actual paints instead of one forced flush per instance.
      obj.forceColorbarRepaint();
    end

    function forceColorbarRepaint(obj)
      % Nudges obj.clb.Position by a throwaway pixel and back, forcing
      % MATLAB to actually flush a repaint of this colorbar rather than
      % trusting an earlier property write to have been painted (see
      % onSettleRefresh's comment above for the empirical evidence this is
      % needed, and why 'limitrate' rather than a plain drawnow). Shared by
      % onSettleRefresh (after a resize/rotation settles) and
      % pollForMissedResize's periodic fallback (for container changes -
      % e.g. dragging a whole docked figure group into the Editor's
      % document tab strip - that leave obj.fig.Position unchanged, so
      % nothing else here ever detects them).
      if ~isempty(obj.clb) && isvalid(obj.clb)
        clbPos = obj.clb.Position;
        obj.clb.Position = clbPos + [0 0 0 1];
        drawnow limitrate;
        obj.clb.Position = clbPos;
        drawnow limitrate;
      end
    end

    function updateColorbarLayout(obj,layout,allowLiveMeasure)
      % allowLiveMeasure gates the rasterize-and-measure step used by the
      % Side='top'+3-D-axes branch below (see its comment for why): true
      % when called from applyProperties (on colorbar()/build or any
      % property change), false from onResize's SizeChangedFcn hot path AND
      % from onViewChanged()'s View-PostSet hot path (see colorbar()'s View
      % listener), where the extra getframe()+drawnow() would reintroduce
      % exactly the kind of per-tick lag the rest of this function's
      % caching already avoids. A plain window resize rescales the 3-D
      % content uniformly without changing its rotation, and reusing the
      % last-measured fraction (obj.Top3DGapFrac) across an actual rotation
      % isn't exact but stays reasonable, so both hot paths share it; the
      % next real property change or colorbar() call re-measures precisely.
      % 1: SCALE FIGURE CONTAINER CANVAS
      %
      % calculate the data aspect ratio
      xl = xlim(obj.ax);
      yl = ylim(obj.ax);
      dataRatio = diff(xl) / diff(yl);
      % fit within the axes' own footprint (captured in colorbar() before
      % any resizing), not the whole figure - this is what keeps a subplot
      % axes inside its own tile instead of expanding over its neighbors
      footprint = obj.OriginalAxesPosition;
      % define margins (as fractions of the footprint) to leave room for
      % labels/ticks - the wide margin goes on whichever side the
      % colorbar/title/logo actually sit on. The left side additionally
      % competes with the axes' own y-tick labels/ylabel (unlike the
      % default right side, where that space is normally unused), so it
      % gets a bigger fixed reservation than the right side's 0.10 - a
      % fixed fraction, rather than measuring the axes' live TightInset,
      % because TightInset is fed back into this same box on every one of
      % applyProperties' 4 settling iterations, which can make it grow
      % unboundedly large (or behave oddly for a rotated 3-D axes) and push
      % the colorbar far off the figure entirely.
      % For 'top'/'bottom' the roles of the horizontal/vertical margins swap:
      % the colorbar (plus its Title/Logo, now beside it rather than above/
      % below it) needs the generous reservation in the vertical direction
      % instead, while left/right stay at the small fixed value nothing
      % else competes for. 'bottom' additionally competes with the axes' own
      % x-tick labels/xlabel the same way 'left' competes with y-tick
      % labels/ylabel above, so it gets the bigger reservation of the two
      % (mirroring 'left' vs 'right').
      switch obj.Side
        case "left"
          marginLeft   = 0.20 * footprint(3);
          marginRight  = 0.02 * footprint(3);
          marginBottom = 0.1  * footprint(4);
          marginTop    = 0.08 * footprint(4);
        case "top"
          marginLeft   = 0.02 * footprint(3);
          marginRight  = 0.02 * footprint(3);
          marginBottom = 0.08 * footprint(4);
          marginTop    = 0.18 * footprint(4); % extra room for the northoutside tick labels above the bar
          if isAxes3D(obj.ax)
            % extra headroom for the fixed safety buffer added in section 2
            % below (see the "top" branch's extraTopBuffer comment)
            marginTop = 0.30 * footprint(4);
          end
        case "bottom"
          marginLeft   = 0.02 * footprint(3);
          marginRight  = 0.02 * footprint(3);
          marginBottom = 0.20 * footprint(4);
          marginTop    = 0.02 * footprint(4);
        otherwise % "right"
          marginLeft   = 0.02 * footprint(3);
          marginRight  = 0.10 * footprint(3);
          marginBottom = 0.1  * footprint(4);
          marginTop    = 0.08 * footprint(4);
      end
      % compute total available width and height for the plot, then fit the
      % axes container to the data aspect ratio within that available space
      x0 = footprint(1) + marginLeft;
      y0 = footprint(2) + marginBottom;
      availW = footprint(3) - marginLeft - marginRight;
      availH = footprint(4) - marginBottom - marginTop;
      box = fitBoxToAspectRatio(x0,y0,availW,availH,dataRatio);
      obj.ax.Units = "normalized";
      obj.ax.Position = box;

      % 2: ALIGN COLORBAR
      %
      % extract true spatial pixel boundaries of the current 2D plot matrix
      axPos = getPlotboxPixels(obj.ax);
      isHorizontalSide = obj.Side == "top" || obj.Side == "bottom";
      % Recompute pixel coordinates maintaining static user configuration
      if isHorizontalSide
        if obj.Side == "bottom"
          % The axes' own X-tick labels (and X-axis label, if any) render
          % immediately below axPos - same competing-space issue as the
          % 'left' branch below, just along the vertical axis instead of
          % the horizontal one - so measure the real label extent the same
          % way, reading TightInset(2) (bottom) in a tight frame instead of
          % TightInset(1) (left).
          curUnits = obj.ax.Units;
          obj.ax.Units = 'pixels';
          curPixelPos = obj.ax.Position;
          obj.ax.Position = axPos;
          tickLabelSpace = obj.ax.TightInset(2);
          obj.ax.Position = curPixelPos;
          obj.ax.Units = curUnits;
          newBottom = axPos(2) - tickLabelSpace - layout.pixelGap - layout.pixelWidth;
          newWidth = axPos(3) * layout.scale;
          newLeft = axPos(1) + (axPos(3) - newWidth) / 2;
        else % "top"
          newWidth = axPos(3) * layout.scale;
          newLeft = axPos(1) + (axPos(3) - newWidth) / 2;
          baselineTop = axPos(2) + axPos(4); % heuristic content top, before any extra buffer
          if isAxes3D(obj.ax)
            % axPos - itself only a heuristic bbox of the projected data
            % corners/tick-label probes, see measure3DContentBBoxPixels -
            % can undershoot the 3-D content's actual rendered top edge at
            % some camera angles, worse at low elevation (confirmed
            % empirically: measuring the true rendered top via getframe()
            % across a range of azimuths/elevations showed the real
            % silhouette landing well above the heuristic, apparently
            % because the topmost rendered point isn't always the max-Z
            % data corner once azimuth/elevation skew the screen-vertical
            % direction - and at near-edge-on elevation the size of that
            % undershoot varies too sharply with azimuth for any single
            % fixed or axPos(4)-scaled buffer to cover safely without
            % either overlapping at one rotation or flying off the top of
            % the figure at another - both observed in testing). So measure
            % the real rendered top directly instead of estimating it:
            % temporarily hide the bar/Title/Logo (their own stale, prior-
            % rotation pixels would otherwise contaminate the measurement),
            % rasterize the actual figure, and scan the intended bar's
            % column span for the topmost non-background pixel.
            %
            % Only done when allowLiveMeasure (see this method's header
            % comment) - the extra drawnow()+getframe() are too slow for
            % the plain-resize hot path, where the content's rotation
            % hasn't changed anyway, so the last-measured gap fraction
            % (obj.Top3DGapFrac) is reused instead, scaled to the current
            % (resized) axPos(4).
            if allowLiveMeasure
              wasClbVisible = obj.clb.Visible;
              obj.clb.Visible = 'off';
              titleVisStates = cell(1,numel(obj.TitleLineObjs));
              for i = 1:numel(obj.TitleLineObjs)
                titleVisStates{i} = obj.TitleLineObjs{i}.Visible;
                obj.TitleLineObjs{i}.Visible = 'off';
              end
              ylbWasVisible = [];
              if ~isempty(obj.ylb) && isvalid(obj.ylb)
                ylbWasVisible = obj.ylb.Visible;
                obj.ylb.Visible = 'off';
              end
              expLblWasVisible = [];
              if ~isempty(obj.ExpLabelObj) && isvalid(obj.ExpLabelObj)
                expLblWasVisible = obj.ExpLabelObj.Visible;
                obj.ExpLabelObj.Visible = 'off';
              end
              drawnow;
              figUnitsM = obj.fig.Units;
              obj.fig.Units = 'pixels';
              figPosPx = obj.fig.Position;
              obj.fig.Units = figUnitsM;
              frame = getframe(obj.fig);
              img = double(frame.cdata);
              H = size(img,1); W = size(img,2);
              % getframe's pixel grid can differ in scale from the figure's
              % own Position units (e.g. HiDPI) - map explicitly rather
              % than assuming 1:1.
              scaleX = W / figPosPx(3);
              scaleY = H / figPosPx(4);
              colMin = max(1, round(newLeft*scaleX));
              colMax = min(W, round((newLeft+newWidth)*scaleX));
              bg = reshape(double(obj.ThemeBgColor)*255, 1, 1, 3);
              searchRowMax = min(H, round(H - axPos(2)*scaleY)); % don't bother scanning past axPos's own bottom
              measuredTop = baselineTop; % fallback if nothing found (shouldn't happen)
              if colMax >= colMin && searchRowMax >= 1
                sub = img(1:searchRowMax, colMin:colMax, :);
                nonBg = any(abs(sub - bg) > 15, 3);
                rowsWithContent = find(any(nonBg,2), 1, 'first');
                if ~isempty(rowsWithContent)
                  % convert the topmost content image-row back to a
                  % figure-Position Y (figure Units are bottom-up; image
                  % rows are top-down)
                  measuredTop = figPosPx(4) - (rowsWithContent-1)/scaleY;
                end
              end
              obj.clb.Visible = wasClbVisible;
              for i = 1:numel(obj.TitleLineObjs)
                obj.TitleLineObjs{i}.Visible = titleVisStates{i};
              end
              if ~isempty(ylbWasVisible)
                obj.ylb.Visible = ylbWasVisible;
              end
              if ~isempty(expLblWasVisible)
                obj.ExpLabelObj.Visible = expLblWasVisible;
              end
              gapNeeded = max(20, measuredTop - baselineTop + 20); % +20px safety margin
              if axPos(4) > 0
                obj.Top3DGapFrac = gapNeeded / axPos(4);
              end
            else
              gapNeeded = axPos(4) * obj.Top3DGapFrac;
            end
            newBottom = baselineTop + layout.pixelGap + gapNeeded;
            % Hard ceiling regardless of the above: better to sit closer to
            % the content at some extreme rotation than to disappear off
            % the top of the figure canvas entirely.
            figUnits = obj.fig.Units;
            obj.fig.Units = 'pixels';
            figHeightPx = obj.fig.Position(4);
            obj.fig.Units = figUnits;
            maxBottom = figHeightPx - layout.pixelWidth - 90; % leave room for tick labels above the bar
            newBottom = min(newBottom, maxBottom);
          else
            newBottom = baselineTop + layout.pixelGap;
          end
        end
        % enforce precise placement layout engine values directly onto the colorbar
        obj.clb.Units = 'pixels';
        obj.clb.Position = [newLeft, newBottom, newWidth, layout.pixelWidth];
      else
        if obj.Side == "left"
          % The axes' own Y-tick labels (and Y-axis label, if any) render
          % immediately to the left of axPos - the true plot box - and their
          % width is NOT reflected in axPos itself (axPos only bounds the
          % plotted data, not its tick decorations). When axis-equal
          % letterboxing insets axPos well inside obj.ax.Position (routine
          % for a non-square data box in a non-square container), those tick
          % labels sit inside that same letterbox slack, which is exactly
          % where a fixed pixelGap places the colorbar - so a fixed gap alone
          % lets the colorbar overlap the tick labels whenever they're wider
          % than pixelGap (they usually are). obj.ax.TightInset only reports
          % overflow beyond obj.ax.Position, which is silent here since the
          % labels sit well within it - so measure the real label extent by
          % briefly fitting obj.ax.Position to axPos itself (tick labels
          % render the same regardless of the container's letterbox slack)
          % and reading TightInset(1) in that tight frame, then restore.
          curUnits = obj.ax.Units;
          obj.ax.Units = 'pixels';
          curPixelPos = obj.ax.Position;
          obj.ax.Position = axPos;
          tickLabelSpace = obj.ax.TightInset(1);
          obj.ax.Position = curPixelPos;
          obj.ax.Units = curUnits;
          newLeft = axPos(1) - tickLabelSpace - layout.pixelGap - layout.pixelWidth;
        else
          newLeft = axPos(1) + axPos(3) + layout.pixelGap;
        end
        newHeight = axPos(4) * layout.scale;
        newBottom = axPos(2) + (axPos(4) - newHeight) / 2;
        % enforce precise placement layout engine values directly onto the colorbar
        obj.clb.Units = 'pixels';
        obj.clb.Position = [newLeft, newBottom, layout.pixelWidth, newHeight];
      end

      % 3: MAKE THE TICKS TO SPAN THE FULL COLORBAR LENGTH
      %
      % dynamically update the tick length to span the full colorbar length;
      % since the colorbar is locked in 'pixels', we can calculate the ratio
      % of its absolute thickness to its absolute length directly
      if isHorizontalSide
        obj.clb.TickLength = layout.pixelWidth/newWidth;
      else
        obj.clb.TickLength = layout.pixelWidth/newHeight;
      end

      % 4/5: ACCURATE PIXEL PLACEMENT OF TITLE AND LOGO AROUND THE COLORBAR
      %
      % For a vertical bar ('left'/'right'), Title stacks above and Logo
      % below, both horizontally aligned over the bar+tick-labels block (see
      % the 'left'/'right' branch below). For a horizontal bar ('top'/
      % 'bottom'), Title sits to its left and Logo to its right instead,
      % both vertically centered on the bar (see the isHorizontalSide branch
      % below) - so the Title/Logo text itself is always read horizontally
      % regardless of Side.
      if isHorizontalSide
        % Anchor 18px beyond each end of the bar along its own length: Logo
        % right-aligned at the left end (grows further left), Title
        % left-aligned at the right end (grows further right) - so Title
        % sits on the high-value end of the tick labels rather than the
        % low-value end, per user feedback. Both are vertically centered on
        % the bar's own thickness.
        pixelLeftEdge  = -18;
        pixelRightEdge = obj.clb.Position(3) + 18;
        vCenter = obj.clb.Position(2) + layout.pixelWidth/2;
        if isAxes3D(obj.ax)
          % Title/Logo are figure-level annotation textboxes here (see
          % applyProperties), so their 'pixels' Position is already in the
          % same absolute, figure-relative frame as obj.clb.Position - no
          % axes-frame conversion needed (see the vertical branch below for
          % the full textbox-Position/FitBoxToText reasoning).
          leftXAbs = obj.clb.Position(1) + pixelLeftEdge;
          rightXAbs = obj.clb.Position(1) + pixelRightEdge;
          % Exponent-only offset of 40 px to move it further right than the
          % Title lines; kept separate from rightXAbs so it doesn't also
          % drag the Title text (rightXAbs anchors both - see below).
          rightXAbsExp = rightXAbs + 40;
          totalH = 0;
          for i = 1:numel(obj.TitleLineObjs)
            totalH = totalH + obj.TitleLineObjs{i}.Position(4);
          end
          currentYAbs = vCenter + totalH/2; % top of the stacked block, centered on the bar
          % stack top-down so TitleLineObjs{1} ends up on top, matching the
          % 2-D horizontal branch and how a native multi-line Title would
          % order the same cell array (was numel:-1:1, which put the LAST
          % line on top instead - reported as reversed row order vs. the
          % 2-D plots)
          for i = 1:numel(obj.TitleLineObjs)
            h = obj.TitleLineObjs{i};
            h.HorizontalAlignment = 'left';
            w = h.Position(3); ht = h.Position(4);
            currentYAbs = currentYAbs - ht;
            h.Position = [rightXAbs, currentYAbs, w, ht];
          end
          if ~isempty(obj.ExpLabelObj) && isvalid(obj.ExpLabelObj)
            % anchored to the bar's own far (outward) end, same end as
            % Title (now the right end - see this method's Title/Logo
            % swap above) - mirrored vertically between 'top' (ticks north
            % of the bar - exponent clears their full height, sitting
            % above them) and 'bottom' (ticks south of the bar - exponent
            % mirrors that, sitting below them) - see the 2D branch below
            % for why the un-mirrored version was wrong for 'bottom'.
            wExp = obj.ExpLabelObj.Position(3); htExp = obj.ExpLabelObj.Position(4);
            % A 3-D horizontal bar packs a fixed capped-mode tick count (see
            % setCappedColorbarLevels) into whatever width layout.scale
            % happens to give it, and MATLAB auto-rotates the tick labels
            % (diagonally) once they'd otherwise overlap each other - a
            % rotated label's true rendered footprint is taller than its
            % own un-rotated text height (obj.TickLabelExtent(2), what this
            % clearance was originally based on), so that height alone
            % undershoots and lets this box collide with the now-diagonal
            % labels. Using the label's full WIDTH as the clearance instead
            % is a conservative upper bound that clears any rotation angle
            % up to 90 degrees, confirmed against a live capped-limits 3-D
            % repro that showed the collision.
            tickLabelClearance = obj.TickLabelExtent(1) + 6;
            obj.ExpLabelObj.HorizontalAlignment = 'right';
            if obj.Side == "top"
              % Added offset of -5 px (top colorbar) to move the exponent on the 
              % top colorbar in the vertical direction
              yExp = obj.clb.Position(2) + layout.pixelWidth + tickLabelClearance - 5;
            else
              % Added offset of +5 px (bottom colorbar) to move the exponent on the 
              % bottom colorbar in the vertical direction            
              yExp = obj.clb.Position(2) - tickLabelClearance - htExp + 5;
            end
            % This controls the position of the exponential label for the top/bottom 
            % colorbar in the 3D case
            obj.ExpLabelObj.Position = [rightXAbsExp - wExp, yExp, wExp, htExp];
          end
          if ~isempty(obj.ylb) && isvalid(obj.ylb)
            obj.ylb.HorizontalAlignment = 'right';
            w = obj.ylb.Position(3); ht = obj.ylb.Position(4);
            obj.ylb.Position = [leftXAbs - w, vCenter - ht/2, w, ht];
          end
          return;
        end
        % Every Title line and the Logo are text objects parented to obj.ax
        % (not the colorbar - see applyProperties for why), so their
        % 'pixels' Position is relative to obj.ax's own corner (axPos)
        % rather than the colorbar's.
        leftX  = obj.clb.Position(1) + pixelLeftEdge  - axPos(1);
        rightX = obj.clb.Position(1) + pixelRightEdge - axPos(1);
        vCenterAx = vCenter - axPos(2);
        totalH = 0;
        for i = 1:numel(obj.TitleLineObjs)
          totalH = totalH + obj.TitleLineObjs{i}.Extent(4);
        end
        currentY = vCenterAx + totalH/2; % top of the stacked block, centered on the bar
        % stack top-down so TitleLineObjs{1} ends up on top, matching how a
        % native multi-line Title would order the same cell array
        for i = 1:numel(obj.TitleLineObjs)
          h = obj.TitleLineObjs{i};
          h.Units = 'pixels';
          h.HorizontalAlignment = 'left';
          h.VerticalAlignment = 'top';
          h.Position(1) = rightX;
          h.Position(2) = currentY;
          currentY = currentY - h.Extent(4); % next line stacks below this one's rendered height
        end
        if ~isempty(obj.ExpLabelObj) && isvalid(obj.ExpLabelObj)
          % anchored to the bar's own far (outward) end, same end as
          % Title (now the right end - see this method's Title/Logo swap
          % above) - mirrored vertically
          % between 'top' (ticks north of the bar - exponent clears their
          % full height, sitting above them, growing upward) and 'bottom'
          % (ticks south of the bar - exponent mirrors that, sitting below
          % them, growing downward). Using the same "grow upward, clear
          % above" logic for 'bottom' left the exponent sandwiched between
          % the axes and the bar (its innermost, axes-facing side) instead
          % of on the bar's outward-facing side like every other Side value.
          tickLabelClearance = obj.TickLabelExtent(2) + 6;
          obj.ExpLabelObj.Units = 'pixels';
          obj.ExpLabelObj.HorizontalAlignment = 'right';
          if obj.Side == "top"
            obj.ExpLabelObj.VerticalAlignment = 'bottom';
            yExp = obj.clb.Position(2) + layout.pixelWidth + tickLabelClearance;
          else
            obj.ExpLabelObj.VerticalAlignment = 'top';
            yExp = obj.clb.Position(2) - tickLabelClearance;
          end
          % nudged 30px right from the bar-aligned default, per user
          % cosmetic tuning against a live screenshot (Side='top')
          obj.ExpLabelObj.Position(1) = rightX + 30;
          obj.ExpLabelObj.Position(2) = yExp - axPos(2);
        end
        if ~isempty(obj.ylb) && isvalid(obj.ylb)
          obj.ylb.Units = 'pixels';
          obj.ylb.HorizontalAlignment = 'right';
          obj.ylb.VerticalAlignment = 'middle';
          obj.ylb.Position(1) = leftX;
          obj.ylb.Position(2) = vCenterAx;
        end
        return;
      end
      % calculate an absolute pixel height above the colorbar top edge
      pixelTopEdge = obj.clb.Position(4) + 18; % Places title 18 pixels above the bar frame
      % Anchor at whichever edge of the bar faces AWAY from the plot, and
      % grow outward from there (over the tick labels, which sit on that
      % same outer side - see the Location/AxisLocation note in
      % applyProperties) rather than inward over the plot itself. For the
      % default right-side bar that's the left edge (x=0), growing
      % rightward; for a left-side bar it's the right edge (x=pixelWidth),
      % growing leftward.
      if obj.Side == "left"
        titleX = layout.pixelWidth;
        titleAlign = 'right';
      else
        titleX = 0;
        titleAlign = 'left';
      end
      if isAxes3D(obj.ax)
        % Title/Logo are figure-level annotation textboxes here (see
        % applyProperties), so their 'pixels' Position is already in the
        % same absolute, figure-relative frame as obj.clb.Position - no
        % axes-frame conversion needed. A textbox's Position is always its
        % bottom-left corner + [w h] (confirmed empirically - assigning
        % only Position(1:2) triggers an unrelated internal re-anchor, so
        % always assign the full 4-element vector at once), and
        % FitBoxToText keeps [w h] sized to the current String/font - read
        % those back rather than assuming a size, then place the box so
        % its outward edge (the one away from the plot, matching titleAlign)
        % lands at the target x.
        baseXAbs = obj.clb.Position(1) + titleX;
        currentYAbs = obj.clb.Position(2) + pixelTopEdge;
        for i = numel(obj.TitleLineObjs):-1:1
          h = obj.TitleLineObjs{i};
          % FitBoxToText's fitted box isn't pixel-tight to the glyphs, and
          % HorizontalAlignment defaults to 'left' - so without this, the
          % text hugs the box's left edge regardless of which edge the box
          % itself is anchored to, leaving a visible gap on the right for
          % Side='left' (box anchored by its right edge) while happening to
          % look flush for Side='right' (box anchored by its own left
          % edge, same edge text already hugs) - purely coincidental, not
          % actually correct.
          h.HorizontalAlignment = titleAlign;
          w = h.Position(3); ht = h.Position(4);
          if titleAlign == "right"
            x = baseXAbs - w;
          else
            x = baseXAbs;
          end
          h.Position = [x, currentYAbs, w, ht];
          currentYAbs = currentYAbs + ht;
        end
        if ~isempty(obj.ExpLabelObj) && isvalid(obj.ExpLabelObj)
          wExp = obj.ExpLabelObj.Position(3); htExp = obj.ExpLabelObj.Position(4);
          expGap = 8;
          if ~isempty(obj.TitleLineObjs)
            % sits on the same row as Title's own last line - TitleLineObjs{end}
            % is the bottom-most one (closest to the bar; see the stacking
            % loop above), immediately following it with a small gap
            lastTitle = obj.TitleLineObjs{end};
            yExp = lastTitle.Position(2);
            if obj.Side == "left"
              % Added +15px to move the exponent on the left colorbar to the right
              xExp = lastTitle.Position(1) - expGap - wExp + 15;
            else
              xExp = lastTitle.Position(1) + lastTitle.Position(3) + expGap;
            end
          else
            % no Title at all - fall back to the tick-label column's own
            % outer edge, right above the bar's top edge
            tickLabelW = obj.TickLabelExtent(1) + 6; % +6px: colorbar's own bar-to-label gap
            yExp = obj.clb.Position(2) + obj.clb.Position(4) + obj.TickLabelExtent(2)/2 + 4;
            if obj.Side == "left"
              % Added +15px to move the exponent on the left colorbar to the right
              xExp = obj.clb.Position(1) - tickLabelW - wExp + 15;
            else
              % Added +0px to move the exponent on the right colorbar to the left
              xExp = obj.clb.Position(1) + layout.pixelWidth + tickLabelW;
            end
          end
          obj.ExpLabelObj.HorizontalAlignment = 'left';
          obj.ExpLabelObj.Position = [xExp, yExp, wExp, htExp];
        end
        if ~isempty(obj.ylb) && isvalid(obj.ylb)
          obj.ylb.HorizontalAlignment = titleAlign; % see TitleLineObjs loop above for why this is needed
          w = obj.ylb.Position(3); ht = obj.ylb.Position(4);
          if titleAlign == "right"
            x = baseXAbs - w;
          else
            x = baseXAbs;
          end
          yTop = obj.clb.Position(2) - 18; % 18px below the bar frame; logo grows downward from here
          obj.ylb.Position = [x, yTop-ht, w, ht];
        end
        return;
      end
      % Every Title line is its own text object parented to obj.ax (not the
      % colorbar - see applyProperties for why), so its 'pixels' Position is
      % relative to obj.ax's own corner (axPos) rather than the colorbar's -
      % convert the colorbar-relative target point (obj.clb.Position(1:2) +
      % [titleX, pixelTopEdge]) into obj.ax's frame by subtracting axPos's
      % corner.
      baseX = obj.clb.Position(1) + titleX - axPos(1);
      baseY = obj.clb.Position(2) + pixelTopEdge - axPos(2);
      currentY = baseY;
      % stack bottom-up so TitleLineObjs{1} ends up on top, matching how a
      % native multi-line Title would order the same cell array
      for i = numel(obj.TitleLineObjs):-1:1
        h = obj.TitleLineObjs{i};
        h.Units = 'pixels';
        h.HorizontalAlignment = titleAlign;
        h.VerticalAlignment = 'bottom';
        h.Position(1) = baseX;
        h.Position(2) = currentY;
        currentY = currentY + h.Extent(4); % next line stacks above this one's rendered height
      end
      if ~isempty(obj.ExpLabelObj) && isvalid(obj.ExpLabelObj)
        expGap = 8;
        if ~isempty(obj.TitleLineObjs)
          % sits on the same row as Title's own last line - TitleLineObjs{end}
          % is the bottom-most one (closest to the bar; see the stacking loop
          % above), immediately following it with a small gap
          lastTitle = obj.TitleLineObjs{end};
          rowY = lastTitle.Position(2);
          if obj.Side == "left"
            expAlign = 'right';
            xTarget = lastTitle.Position(1) - lastTitle.Extent(3) - expGap;
          else
            expAlign = 'left';
            xTarget = lastTitle.Position(1) + lastTitle.Extent(3) + expGap;
          end
        else
          % no Title at all - fall back to the tick-label column's own
          % outer edge, right above the bar's top edge
          tickLabelW = obj.TickLabelExtent(1) + 6; % +6px: colorbar's own bar-to-label gap
          rowY = (obj.clb.Position(2) + obj.clb.Position(4) + obj.TickLabelExtent(2)/2 + 4) - axPos(2);
          if obj.Side == "left"
            expAlign = 'left';
            xTarget = obj.clb.Position(1) - tickLabelW - axPos(1);
          else
            expAlign = 'right';
            xTarget = obj.clb.Position(1) + layout.pixelWidth + tickLabelW - axPos(1);
          end
        end
        obj.ExpLabelObj.Units = 'pixels';
        obj.ExpLabelObj.HorizontalAlignment = expAlign;
        obj.ExpLabelObj.VerticalAlignment = 'bottom';
        % nudged 25px outward (away from the bar) / 10px down from the
        % bar-aligned default, per user cosmetic tuning against a live
        % screenshot - mirrored by Side so it moves AWAY from the title on
        % both sides: for 'right', xTarget already sits to the right of
        % Title, so +25 pushes it further right/outward; for 'left',
        % xTarget sits to the LEFT of Title, so the same +25 would instead
        % push it back toward/into Title, which is exactly the overlap the
        % un-mirrored version caused.
        if obj.Side == "left"
          horizNudge = -25;
        else
          horizNudge = 25;
        end
        obj.ExpLabelObj.Position(1) = xTarget + horizNudge;
        obj.ExpLabelObj.Position(2) = rowY - 10;
      end

      % ACCURATE PIXEL CENTERING OF LOGO BELOW THE COLORBAR OVER BOTH BAR AND TICK LABELS
      %
      if ~isempty(obj.ylb) && isvalid(obj.ylb)
        % the Logo is a standalone text object parented to obj.ax (not the
        % colorbar - see applyProperties for why), so its 'pixels' Position
        % is relative to obj.ax's own corner (axPos), same conversion as
        % TitleLineObjs above: take the colorbar-relative target point
        % (obj.clb.Position(1:2) + [titleX, -18], 18 px below the bar
        % frame, anchored/aligned the same outward-facing way as the Title
        % above) and subtract axPos's corner to land in obj.ax's frame.
        obj.ylb.Units = 'pixels';
        obj.ylb.Position(1) = obj.clb.Position(1) + titleX - axPos(1);
        obj.ylb.Position(2) = obj.clb.Position(2) - 18 - axPos(2);
        obj.ylb.HorizontalAlignment = titleAlign;
        obj.ylb.VerticalAlignment = 'top';
      end
    end

    function [w,h] = measureTickLabelExtent(obj)
      % Pixel [width height] of the widest current tick label, used to
      % anchor TickLabelsAutoScale's exponent annotation flush with the
      % tick-label column/row's own outer edge - independent of wherever
      % Title happens to be, since the annotation is conceptually part of
      % the tick labels, not the Title. obj.clb.TickLabels already carries
      % the '\color[rgb]{...}' tag injected by setColorbarLevels/
      % setCappedColorbarLevels - stripped here so the probe measures only
      % the visible text.
      longest = '';
      for i = 1:numel(obj.clb.TickLabels)
        s = regexprep(obj.clb.TickLabels{i},'\\color\[rgb\]\{[^}]*\}','');
        if numel(s) > numel(longest)
          longest = s;
        end
      end
      if isempty(longest)
        w = 0; h = 0;
        return
      end
      probe = text(obj.ax,0,0,longest,'Units','pixels','Visible','off', ...
          'FontName',obj.TickLabelsFontName,'FontSize',obj.TickLabelsFontSize, ...
          'FontWeight',obj.TickLabelsFontWeight);
      w = probe.Extent(3);
      h = probe.Extent(4);
      delete(probe);
    end
    %
    function setColorbarLevels(obj,hideTicksAndBox,expN)
      nc = obj.NumColormapColors;
      if isempty(nc), nc = 8; end % default number of colors
      cmapName = obj.ColormapName;

      % 0: DETERMINE HOW MANY COLOR LEVELS SEPARATE EACH VISIBLE TICKLABEL,
      % AND PAD nc (IF NEEDED) SO IT DIVIDES EVENLY INTO THAT STEP.
      %
      % nc  <= 18          : label every color level (step = 1)
      % 18  < nc < 31       : label every 2nd color level
      % 31 <= nc < 51       : label every 3rd color level
      % 51 <= nc < 81       : label every 4th color level
      % nc >= 81            : label every 5th color level
      %
      % NOTE: the original code used a single "if rem(nc,4)~=0, nc=nc+1"
      % for the 51<=nc<81 case, which does not always land on a multiple of
      % 4 (e.g. nc=53 -> 54, still not divisible by 4). Using a while loop
      % consistently for every range fixes that.
      step = getLabelStep(nc);
      while rem(nc,step) ~= 0
        nc = nc + 1;
      end

      % 1: CREATE THE COLORMAP
      %
      cmapFunction = str2func(cmapName);
      colormap(obj.ax,cmapFunction(nc));

      % re-sync the colorbar's Limits from the axes' actual CLim before
      % using it below. Setting 'ylim' on the colorbar further down (step
      % 2) silently flips its LimitsMode from 'auto' to 'manual' the first
      % time this runs, which stops obj.clb.Limits from auto-tracking any
      % later clim() change (e.g. via setLimits()/resetLimits()) - so from
      % then on, obj.clb.Limits would go stale unless refreshed explicitly
      % here on every rebuild.
      obj.clb.Limits = clim(obj.ax);

      % 2: FORMAT TICKLABELS FOR EACH COLOR LEVEL IN THE COLORBAR
      %
      tickStep = (obj.clb.Limits(2)-obj.clb.Limits(1))/nc;
      set(obj.clb,'ylim',obj.clb.Limits,'ytick',(obj.clb.Limits(1):tickStep:obj.clb.Limits(2))');
      fmt = obj.TickLabelsFormat;
      if obj.TickLabelsAutoScale
        fmt = sprintf('%%+.%df',obj.TickLabelsAutoScaleDecimals);
      end
      L = cellfun(@(x)sprintf(fmt,x/10^expN),num2cell(get(obj.clb,'ytick')),'Un',0);
      set(obj.clb,'yticklabel',L);

      % remove TickLabels depending on the number of colors in the colorbar:
      % keep only every step-th label (starting at index 1), blank the rest.
      % This single block replaces four near-identical branches that built
      % the same result in slightly different ways for each step value.
      if step > 1
        tlabels = cell(size(obj.clb.TickLabels));
        tlabels(1:step:end) = obj.clb.TickLabels(1:step:end);
        obj.clb.TickLabels = tlabels;
      end

      % force tex rendering so styles coincide whether or not ticks are
      % hidden; color follows the theme font color set in colorbar() so
      % labels stay legible against either a light or dark background
      fontRGB = sprintf('%.4g,%.4g,%.4g',obj.ThemeFontColor);
      for i = 1:length(obj.clb.TickLabels)
        obj.clb.TickLabels{i} = ['\color[rgb]{',fontRGB,'}',obj.clb.TickLabels{i}];
      end
      if hideTicksAndBox
        % hide ticks and box by blending them into the background color;
        % ticklabels stay visible because their color was forced above
        % independently
        obj.clb.LineWidth = obj.TickLineWidth*1.5;
        obj.clb.Color = obj.ThemeBgColor;
      else
        % contrast the box/ticks against the background so they're visible
        obj.clb.Color = obj.ThemeFontColor;
      end
    end

    function setCappedColorbarLevels(obj,hideTicksAndBox,expN)
      % Capped-mode counterpart to setColorbarLevels(): instead of
      % stretching the gradient colormap over obj.CappedLimits, it appends
      % two fixed threshold colors (obj.CappedColorBelow/obj.CappedColorAbove)
      % on either end and maps them to a one-delta-wide sliver of CLim just
      % outside [minVal maxVal], so every value at/below minVal or at/above
      % maxVal saturates to that fixed color instead of the gradient's own
      % end colors. Ticks/labels are built to match: a '<'/'>' - prefixed
      % label at the boundary between the gradient and each threshold
      % color, and no label at the two outermost (padding) ticks.
      minVal = obj.CappedLimits(1);
      maxVal = obj.CappedLimits(2);
      nc = obj.NumColormapColors;
      if isempty(nc), nc = 8; end % default number of colors

      % 1: BUILD THE CAPPED COLORMAP
      %
      cmapFunction = str2func(obj.ColormapName);
      gradientCmap = cmapFunction(nc);
      colormap(obj.ax,[obj.CappedColorBelow; gradientCmap; obj.CappedColorAbove]);

      % 2: AUGMENT THE DATA RANGE BY ONE DELTA BELOW AND ABOVE, AND MAP IT
      % TO THE CAPPED COLORMAP
      %
      delta = abs(maxVal-minVal)/nc;
      cappedMin = minVal-delta;
      cappedMax = maxVal+delta;
      clim(obj.ax,[cappedMin,cappedMax]);
      obj.clb.Limits = [cappedMin,cappedMax]; % see the LimitsMode note in setColorbarLevels

      % 3: CUSTOM TICKS AND LABELS
      %
      gradientTicks = linspace(minVal,maxVal,nc+1);
      customTicks = [cappedMin,gradientTicks,cappedMax];
      fmt = obj.TickLabelsFormat;
      if obj.TickLabelsAutoScale
        fmt = sprintf('%%+.%df',obj.TickLabelsAutoScaleDecimals);
      end
      L = cellfun(@(x)sprintf(fmt,x/10^expN),num2cell(customTicks),'Un',0);
      % mark the boundary labels with '<'/'>', then blank the two outermost
      % (padding) ticks - they exist only to give the threshold colors a
      % sliver of CLim to render in, not to be labeled themselves
      L{2} = ['<',L{2}];
      L{end-1} = ['>',L{end-1}];
      L{1} = '';
      L{end} = '';
      obj.clb.Ticks = customTicks;
      obj.clb.TickLabels = L;

      % force tex rendering so styles coincide whether or not ticks are
      % hidden; color follows the theme font color set in colorbar() so
      % labels stay legible against either a light or dark background
      fontRGB = sprintf('%.4g,%.4g,%.4g',obj.ThemeFontColor);
      for i = 1:numel(obj.clb.TickLabels)
        if ~isempty(obj.clb.TickLabels{i})
          obj.clb.TickLabels{i} = ['\color[rgb]{',fontRGB,'}',obj.clb.TickLabels{i}];
        end
      end
      if hideTicksAndBox
        obj.clb.LineWidth = obj.TickLineWidth*1.5;
        obj.clb.Color = obj.ThemeBgColor;
      else
        obj.clb.Color = obj.ThemeFontColor;
      end
    end

  end

end

% ==========================================================================
% LOCAL FUNCTIONS
%
% These live outside the classdef block on purpose. They used to be private
% Static methods, but calling a classdef method - even a static one - goes
% through MATLAB's method dispatch, which has measurable per-call overhead
% for handle classes. getLabelStep, fitBoxToAspectRatio, and getPlotboxPixels
% all sit on the SizeChangedFcn resize path, which can fire many times per
% second while a figure window is being dragged, so that overhead compounds
% into visible lag. Plain local functions are called directly with no
% dispatch, so they keep the single-source-of-truth benefit of the earlier
% refactor without paying that cost on every resize tick.
% checkAndAssign and getStyleParams aren't on the hot path (they only run
% once per build/refresh, not per resize tick) but are kept here too for
% consistency.
% ==========================================================================

function val = readNumberPrompt(promptTxt)
  % Reads a numeric value for niceColorbar.session()'s prompts as raw text
  % ('s' flag) and converts it with str2double, rather than letting input()
  % evaluate the typed text as a MATLAB expression. A bare input() call
  % evaluates whatever is typed in the calling workspace - i.e. session()'s,
  % which lives in this same file - so typing the name of any local function
  % here (e.g. a colormap name like 'spectral', typed by mistake at a
  % numeric prompt) would call that function with zero arguments instead of
  % failing cleanly. str2double never executes code: unparsable text simply
  % becomes NaN, which the caller checks for.
  txt = strtrim(input(promptTxt,'s'));
  val = str2double(txt);
end

function tf = isMatlabDarkMode(fig)
  % Detects whether MATLAB is currently rendering in dark mode. Only runs
  % once per colorbar() build (not on the resize hot path), so the small
  % overhead of the try/catch cascade below doesn't matter.
  %
  % 1) theme(fig).BaseColorStyle - the documented, authoritative API
  %    (R2025a+): reflects what this exact figure will render with, even
  %    when the user's MATLABTheme preference is 'auto' (follow system).
  % 2) settings().matlab.appearance.MATLABTheme.ActiveValue - the resolved
  %    desktop theme setting, for releases where theme(fig) isn't available.
  % 3) The Windows "apps use light theme" registry value, for releases that
  %    predate both APIs above but where MATLAB still follows the OS theme.
  % Defaults to light - this class's historical behavior - if none apply.
  %
  % NOTE: an earlier version of this fallback read a Java desktop
  % preference ('isDesktopUsingDarkColors') that turned out not to exist on
  % at least one real MATLAB install; Prefs.getBooleanPref() silently
  % returns its default (false) for a missing key instead of erroring, so
  % that path always reported light mode with no error to signal it. It's
  % been replaced by the two verified fallbacks below.
  try
    gt = theme(fig);
    tf = strcmpi(gt.BaseColorStyle,'dark');
    return
  catch
  end
  try
    s = settings;
    tf = strcmpi(s.matlab.appearance.MATLABTheme.ActiveValue,'Dark');
    return
  catch
  end
  if ispc()
    try
      v = winqueryreg('HKEY_CURRENT_USER', ...
        'Software\Microsoft\Windows\CurrentVersion\Themes\Personalize', ...
        'AppsUseLightTheme');
      tf = (v == 0);
      return
    catch
    end
  else
    % Neither theme(fig) nor settings() resolved anything above, and the
    % Windows-registry fallback doesn't apply here, so there's no verified
    % way left to read the OS theme on Mac/Linux. Rather than silently
    % guessing, tell the user light colors were assumed and how to override.
    warning('niceColorbar:isMatlabDarkMode:unverifiedPlatform', ...
      ['Could not detect system dark/light mode on this platform; ' ...
       'defaulting to light colors. Set ThemeMode to ''light'' or ' ...
       '''dark'' explicitly to avoid this warning and get the correct look.']);
  end
  tf = false;
end

function wrapped = wrapCommaList(items,maxWidth)
  % Joins items with ', ' and breaks the result into multiple lines, each
  % no wider than maxWidth columns - used for error/help messages that
  % enumerate long lists (e.g. every valid colormap name), which otherwise
  % print as a single line far wider than a typical terminal.
  wrapped = '';
  lineLen = 0;
  for i = 1:numel(items)
    piece = items{i};
    if i < numel(items)
      piece = [piece,', ']; %#ok<AGROW>
    end
    if lineLen > 0 && lineLen + length(piece) > maxWidth
      wrapped = [wrapped,newline]; %#ok<AGROW>
      lineLen = 0;
    end
    wrapped = [wrapped,piece]; %#ok<AGROW>
    lineLen = lineLen + length(piece);
  end
end

function checkAndAssign(propName,val,validators,errMsg)
  % Runs each validator function handle on val; on failure, raises a
  % niceColorbar-specific error carrying the friendly message. This
  % centralizes what used to be a duplicated try/catch in every setter.
  %
  % NOTE: the identifier is 'niceColorbar:set<PropName>:valueError' (no
  % period before PropName). A period inside a colon-separated component
  % is not a valid MATLAB message identifier - MException() rejects it in
  % current MATLAB releases with "Identifier must be a valid MATLAB
  % message identifier", which silently replaced every one of this
  % class's friendly validation messages with that generic error instead.
  try
    for k = 1:numel(validators)
      validators{k}(val);
    end
  catch
    ME = MException(sprintf('niceColorbar:set%s:valueError',propName),errMsg);
    throw(ME);
  end
end

function mustBeColorSpec(val)
  % Accepts anything MATLAB's own graphics 'Color' properties accept: a
  % color name / character vector / hex string (text), or a 1x3 RGB
  % triplet with components in [0,1]. mustBeText alone (the original
  % validator) rejected numeric RGB triplets even though the underlying
  % graphics property has always supported them.
  if isnumeric(val)
    if ~(isrow(val) && numel(val)==3 && all(val>=0 & val<=1))
      error('niceColorbar:mustBeColorSpec:invalidValue', ...
        'value must be a 1x3 RGB triplet with components in [0,1]');
    end
  elseif ~(ischar(val) || isstring(val))
    error('niceColorbar:mustBeColorSpec:invalidValue', ...
      'value must be a color name, character vector, or 1x3 RGB triplet');
  end
end

function mustBeTitleColorSpec(val)
  % TitleColor accepts: [] (auto-follow the theme for the whole Title), a
  % single color spec (overrides the whole Title), or a cell array of color
  % specs/[] - one per Title line - for per-line coloring (see
  % applyProperties/updateColorbarLayout in niceColorbar).
  if isempty(val)
    return
  elseif iscell(val)
    for k = 1:numel(val)
      if ~isempty(val{k})
        mustBeColorSpec(val{k});
      end
    end
  else
    mustBeColorSpec(val);
  end
end

function names = getValidColormapNames()
  % Enumerates every colormap name niceColorbar's ColormapName property
  % will accept. colormaplist() (R2025b+) is MATLAB's own, always-current
  % registry of built-in colormaps, so preferring it here means this list
  % never drifts out of sync with what MATLAB itself actually ships. On
  % older releases where colormaplist() doesn't exist yet, fall back to a
  % fixed list of colormap functions that have shipped with MATLAB for a
  % long time.
  %
  % Validating against this list directly in the ColormapName setter (via
  % mustBeMember) matters because an invalid name that instead only failed
  % later, inside setColorbarLevels, would be triggered asynchronously by
  % the PostSet auto-refresh listener - and MATLAB downgrades an error
  % thrown from inside a listener callback into a console warning rather
  % than letting it propagate to the caller, so a surrounding try/catch
  % (e.g. in niceColorbar.session()) would never see it. Rejecting the bad
  % name synchronously in the setter avoids that entirely.
  try
    names = cellstr(colormaplist());
  catch
    % sky/abyss/nebula are omitted here: they shipped alongside colormaplist()
    % itself (R2025b+), so a release old enough to land in this catch branch
    % never has them as callable functions either
    names = {'parula','turbo','hsv','hot','cool','spring','summer','autumn', ...
      'winter','gray','bone','copper','pink','jet', ...
      'lines','colorcube','prism','flag','white'};
  end
  names = [reshape(names,1,[]), getCustomColormapNames()];
end

function names = getCustomColormapNames()
  % names of the custom colormaps implemented below (see "CUSTOM COLORMAPS"),
  % kept in sync with the function names str2func(cmapName) must resolve to
  names = {'darkjet','feap','nice','acefem','paraview','fast','robot','ultra', ...
    'adina','adina2','vemlab','watermelon','darkwatermelon','polar','roma', ...
    'cork','lime','limediv','spectral','RdYlBu','simsolid'};
end

function step = getLabelStep(nc)
  % number of color levels between consecutive visible TickLabels
  if nc > 18 && nc < 31
    step = 2;
  elseif nc >= 31 && nc < 51
    step = 3;
  elseif nc >= 51 && nc < 81
    step = 4;
  elseif nc >= 81
    step = 5;
  else
    step = 1;
  end
end

function n = autoScaleExponent(limitsVal)
  % power-of-10 exponent for TickLabelsAutoScale, derived purely from the
  % magnitude of the data range - n=0 (values already order-1) means "no
  % scaling needed", which callers use to suppress the annotation entirely
  maxAbs = max(abs(limitsVal));
  if maxAbs == 0 || ~isfinite(maxAbs)
    n = 0;
  else
    n = floor(log10(maxAbs));
  end
end

function tf = isAxes3D(ax)
  % A 2-D view (the default, and what view(ax,2) restores) sits at
  % elevation 90 looking straight down; any other elevation means the
  % axes has been rotated into a 3-D view (e.g. via view(ax,3) or surf's
  % default view). Used by getPlotboxPixels to anchor the colorbar to the
  % axes' full pixel footprint in 3-D, rather than to a data-aspect-ratio
  % sub-box that assumes a straight-on 2-D view - that assumption
  % undershoots a rotated 3-D plot's real extent, letting the colorbar
  % overlap it and defeat the 'ultra' styles' hide-ticks-and-box effect
  % (which relies on the colorbar sitting over plain background, not over
  % the plot itself).
  v = get(ax,'View');
  tf = v(2) ~= 90;
end

function styleParams = getStyleParams()
  % single source of truth for the six style presets; scale and pixelGap
  % are identical across all of them in the original code, only pixelWidth
  % and hideTicksAndBox vary.
  names       = {'modern','modern.thin','modern.thick','ultra','ultra.thin','ultra.thick'};
  pixelWidths = [40, 25, 55, 40, 25, 55];
  hideTicks   = [false, false, false, true, true, true];
  styleParams = containers.Map();
  for i = 1:numel(names)
    styleParams(names{i}) = struct('scale',0.6,'pixelGap',15, ...
      'pixelWidth',pixelWidths(i), ...
      'hideTicksAndBox',hideTicks(i));
  end
end

function box = fitBoxToAspectRatio(x0,y0,availW,availH,dataRatio)
  % Fits a box of aspect ratio dataRatio inside the available
  % [x0,y0,availW,availH] region, centering it along the axis that has
  % slack. Shared by updateColorbarLayout (normalized units) and
  % getPlotboxPixels (pixel units) below, which used to duplicate this
  % exact fitting logic.
  availRatio = availW / availH;
  if dataRatio > availRatio
    % data is wider than the available canvas shape -> span full available width
    w = availW;
    h = availW / dataRatio;
    x = x0;
    y = y0 + (availH - h) / 2; % vertically centered
  else
    % data is taller than the available canvas shape -> span full available height
    h = availH;
    w = availH * dataRatio;
    y = y0;
    x = x0 + (availW - w) / 2; % horizontally centered
  end
  box = [x, y, w, h];
end

function pos = getPlotboxPixels(hAx)
  % caches previous active handle unit tracking schemas dynamically
  oldUnits = hAx.Units;
  hAx.Units = 'pixels';
  axPos = hAx.Position;
  if isAxes3D(hAx)
    % A rotated 3-D view's rendered content (cube + its tick labels, which
    % trail off diagonally past the cube's own corners depending on
    % azimuth/elevation) is letterboxed within hAx.Position by MATLAB's
    % camera projection in a way that has no closed-form aspect ratio -
    % assuming the full rectangle undershoots the plot and causes overlap
    % (the original bug this branch existed to fix), but overshoots just
    % as easily for a wide/short container, leaving a large dead gap
    % between the plot and a colorbar anchored to the full rectangle's
    % edge instead. Projecting just the 8 data corners (an earlier attempt
    % here) undershoots too, in the other direction, because it misses how
    % far the tick label TEXT extends beyond its anchor corner - and
    % TightInset doesn't help either (empirically confirmed unreliable for
    % a rotated 3-D axes). A rasterize-and-diff approach (an even earlier
    % attempt) measured this correctly on a settled figure, but depends on
    % getframe() catching an already-fully-rendered frame - during a fast
    % interactive resize drag (this runs on the SizeChangedFcn hot path)
    % that's not guaranteed, and a frame caught mid-render silently falls
    % back to the full rectangle, reintroducing the exact gap bug it was
    % meant to fix. So measure it analytically and synchronously instead:
    % project the 8 data corners AND the first/last tick label of each
    % axis (at every combination of the other two axes' extremes, since
    % which wall MATLAB actually draws each ruler's labels on isn't known
    % up front) through the current view, and take their combined pixel
    % Extent - this only touches text-object properties MATLAB computes
    % immediately on creation, with no dependency on render timing.
    pos = measure3DContentBBoxPixels(hAx, axPos);
  else
    dar = hAx.DataAspectRatio;
    xl = hAx.XLim; yl = hAx.YLim;
    dataWidth = diff(xl) / dar(1);
    dataHeight = diff(yl) / dar(2);
    dataRatio = dataWidth / dataHeight;
    pos = fitBoxToAspectRatio(axPos(1),axPos(2),axPos(3),axPos(4),dataRatio);
  end
  hAx.Units = oldUnits; % restores previous active units system tracking parameters
end

function box = measure3DContentBBoxPixels(hAx,axPosFull)
  % Projects the 8 data corners AND every tick label of X/Y/Z (each placed
  % at every combination of the other two axes' extreme values, since
  % which wall MATLAB actually renders a given ruler's labels on isn't
  % known up front) through the axes' current view, using the real label
  % strings so each probe's pixel Extent reports exactly how far that
  % label's rendered text reaches - not just its anchor point. A uniform
  % size-based pad (an earlier attempt here) assumed a label sticks out
  % only near the cube's own corners, but a tick label can land well
  % inside one wall's silhouette at a middling screen height depending on
  % azimuth/elevation, so a pad anchored to the corners alone can still
  % undershoot; probing the labels' actual projected positions (not just
  % their size) is the only approach confirmed to clear every case tried
  % (a small figure, a wide post-resize window, and both Side settings).
  [minX,maxX,minY,maxY] = project3DCornersPixels(hAx);
  xl = hAx.XLim; yl = hAx.YLim; zl = hAx.ZLim;
  [minX,maxX,minY,maxY] = expandWithTickLabelProbes(hAx,minX,maxX,minY,maxY,hAx.XTick,hAx.XTickLabel,1,yl,zl);
  [minX,maxX,minY,maxY] = expandWithTickLabelProbes(hAx,minX,maxX,minY,maxY,hAx.YTick,hAx.YTickLabel,2,xl,zl);
  [minX,maxX,minY,maxY] = expandWithTickLabelProbes(hAx,minX,maxX,minY,maxY,hAx.ZTick,hAx.ZTickLabel,3,xl,yl);
  % Small fixed safety buffer on top of the probed extent, X only: the
  % probes above assume each tick label is centered on its data anchor,
  % but MATLAB's actual alignment/foreshortening can shift a label a bit
  % further outward than that near a rotated 3-D box's silhouette edge - a
  % modest constant absorbs that residual. Deliberately NOT applied to Y:
  % Side is always a left/right choice, so only the horizontal clearance
  % matters for where the colorbar attaches: Y is also used to scale the
  % colorbar's own height (newHeight = axPos(4)*layout.scale in
  % updateColorbarLayout) - padding it the same way would make the
  % colorbar taller for no reason, and paradoxically more likely to cross
  % a label somewhere along that extra height.
  buf = 150;
  minX = minX-buf;
  maxX = maxX+buf;
  % Clamp both edges to a band of the full axes rectangle's width: a floor
  % on the outward side (MATLAB draws each wall's own grid a small margin
  % past the exact data corners, which the probes don't account for and
  % which held up even a generous fixed buffer for a small/dense plot - a
  % lot of close-packed gridlines) and a ceiling on the same side (the
  % probes plus buf can also overshoot - e.g. a tick label probed near one
  % side pushing that edge far past what's actually needed - which for a
  % small figure pushed the opposite Side's colorbar clean off the
  % figure). The probe measurement still wins within the band (tighter, no
  % dead gap) for the common case where it already clears comfortably.
  minX = max(min(minX, 0.15*axPosFull(3)), -0.05*axPosFull(3));
  maxX = min(max(maxX, 0.85*axPosFull(3)), 1.05*axPosFull(3));
  box = [axPosFull(1)+minX, axPosFull(2)+minY, maxX-minX, maxY-minY];
end

function [minX,maxX,minY,maxY] = expandWithTickLabelProbes(hAx,minX,maxX,minY,maxY,ticks,labels,axisIdx,otherA,otherB)
  % Grows [minX,maxX,minY,maxY] to also cover the first, middle, and last
  % tick's label text (with its real string, so Extent reflects its true
  % rendered size), placed at each combination of the other two axes'
  % extreme values. A sample, not every tick: this runs on the
  % SizeChangedFcn/property-refresh hot path, and probing every tick (a
  % text create+delete each) was measured to add multiple seconds of lag
  % for a plot with many ticks. The middle tick is included alongside the
  % extremes because a dense grid of many close-packed ticks can render an
  % interior label further out (screen-space) than either extreme, past
  % what the extremes-only probes plus the proportional safety floor below
  % would catch (an actual overlap found in testing) - sampling the middle
  % tick too closes that gap without paying for every tick.
  if isempty(ticks)
    return;
  end
  otherIdx = setdiff(1:3,axisIdx);
  for k = unique([1,ceil(numel(ticks)/2),numel(ticks)])
    for a = otherA
      for b = otherB
        pt = zeros(1,3);
        pt(axisIdx) = ticks(k);
        pt(otherIdx(1)) = a;
        pt(otherIdx(2)) = b;
        h = text(hAx,pt(1),pt(2),pt(3),labels{k},'Units','data','Visible','off', ...
                  'HorizontalAlignment','center','VerticalAlignment','middle');
        h.XLimInclude = 'off'; h.YLimInclude = 'off'; h.ZLimInclude = 'off';
        h.Units = 'pixels';
        ext = h.Extent;
        delete(h);
        minX = min(minX,ext(1)); maxX = max(maxX,ext(1)+ext(3));
        minY = min(minY,ext(2)); maxY = max(maxY,ext(2)+ext(4));
      end
    end
  end
end

function [minX,maxX,minY,maxY] = project3DCornersPixels(hAx)
  % Projects the 8 corners of the [XLim,YLim,ZLim] data box through the
  % axes' current view (a zero-size invisible text object anchored with
  % Units='data' reports its actual projected screen position once its
  % Units are flipped to 'pixels' - the only supported way to read back a
  % 3-D-to-2-D projected point) and returns their pixel bounding box, in a
  % frame local to hAx's own pixel corner.
  xl = hAx.XLim; yl = hAx.YLim; zl = hAx.ZLim;
  corners = [xl(1) yl(1) zl(1); xl(2) yl(1) zl(1); xl(1) yl(2) zl(1); xl(2) yl(2) zl(1); ...
             xl(1) yl(1) zl(2); xl(2) yl(1) zl(2); xl(1) yl(2) zl(2); xl(2) yl(2) zl(2)];
  minX = inf; maxX = -inf; minY = inf; maxY = -inf;
  for i = 1:size(corners,1)
    h = text(hAx,corners(i,1),corners(i,2),corners(i,3),'','Units','data','Visible','off');
    h.XLimInclude = 'off'; h.YLimInclude = 'off'; h.ZLimInclude = 'off';
    h.Units = 'pixels';
    minX = min(minX,h.Position(1)); maxX = max(maxX,h.Position(1));
    minY = min(minY,h.Position(2)); maxY = max(maxY,h.Position(2));
    delete(h);
  end
end

% ==========================================================================
% CUSTOM COLORMAPS
%
% Each function below is named exactly after the ColormapName value it
% implements, since setColorbarLevels() resolves ColormapName via
% str2func(cmapName)(nc) - str2func only finds a local function like these
% when called (as it is here) from within this same file. Every custom map
% is defined by a handful of RGB control points and interpolated up to
% numcolors samples via interpColormapPoints(), the same way MATLAB's own
% colormap functions (parula, turbo, etc.) accept a single numcolors input
% and return an numcolors-by-3 array.
% ==========================================================================

function mymap = interpColormapPoints(xrgb,method,numcolors)
  % xrgb: Nx4 control points [x, r, g, b] with x spanning [0,1]
  xsamp = linspace(0,1,numcolors);
  rq = min(max(interp1(xrgb(:,1),xrgb(:,2),xsamp,method),0),1); % ensure values in [0,1]
  gq = min(max(interp1(xrgb(:,1),xrgb(:,3),xsamp,method),0),1); % ensure values in [0,1]
  bq = min(max(interp1(xrgb(:,1),xrgb(:,4),xsamp,method),0),1); % ensure values in [0,1]
  mymap = [rq',gq',bq'];
end

function mymap = darkjet(numcolors)
  xrgb = [0         0         0    0.4902
          0.0625    0.0039    0.0588    0.6039
          0.1250    0.0118    0.1294    0.7020
          0.1875    0.0078    0.2353    0.8039
          0.2500    0.0196    0.3765    0.9216
          0.3125    0.0392    0.5961    1.0000
          0.3750    0.0431    1.0000    0.9608
          0.4375    0.0980    0.7176    0.3294
          0.5000    0.1961    0.5569    0.1020
          0.5625    0.6510    0.8510    0.1020
          0.6250    1.0000    0.9804    0.0784
          0.6875    1.0000    0.7490    0.0549
          0.7500    1.0000    0.5412    0.0471
          0.8125    1.0000    0.2588    0.0196
          0.8750    0.9216    0.1647    0.0078
          0.9375    0.7647    0.0824         0
          1.0000    0.4902         0         0];
  mymap = interpColormapPoints(xrgb,'spline',numcolors);
end

function mymap = feap(numcolors)
  xrgb = [0.0000	0.6275	0.1255	0.8784
          0.0909	0.0000	0.0000	1.0000
          0.1818	0.2549	0.4118	1.0000
          0.2727	0.0000	1.0000	1.0000
          0.3636	0.4980	1.0000	0.8314
          0.4545	0.0000	1.0000	0.0000
          0.5455	0.6784	1.0000	0.1843
          0.6364	1.0000	1.0000	0.0000
          0.7273	0.9608	0.8706	0.7020
          0.8182	1.0000	0.6471	0.0000
          0.9091	1.0000	0.4980	0.3137
          1.0000	1.0000	0.0000	0.0000];
  mymap = interpColormapPoints(xrgb,'linear',numcolors);
end

function mymap = nice(numcolors)
  xrgb = [0.0000	0.6275	0.1255	0.8784
          0.0909	0.3059	0.3059	0.9255
          0.1818	0.4275	0.5490	0.9922
          0.2727	0.7059	0.7686	1.0000
          0.3636	0.8510	0.8824	1.0000
          0.4545	0.9725	0.9765	1.0000
          0.5455	1.0000	0.9961	0.8235
          0.6364	0.9882	0.9922	0.4980
          0.7273	0.9922	0.8431	0.5059
          0.8182	1.0000	0.7176	0.1137
          0.9091	1.0000	0.4431	0.4431
          1.0000	1.0000	0.0000	0.0000];
  mymap = interpColormapPoints(xrgb,'linear',numcolors);
end

function mymap = acefem(numcolors)
  xrgb = [0.0000	0.2745	0.4078	0.9412
          0.1429	0.5020	0.6000	0.9529
          0.2857	0.7765	0.8314	0.9843
          0.4286	0.9490	0.9608	0.9804
          0.5714	0.9961	0.9922	0.7725
          0.7143	0.9843	0.9608	0.3882
          0.8571	0.9176	0.7098	0.2549
          1.0000	0.8510	0.3725	0.1961];
  mymap = interpColormapPoints(xrgb,'linear',numcolors);
end

function mymap = paraview(numcolors)
  xrgb = [0.0000	0.2314	0.2980	0.7529
          0.0667	0.3098	0.4157	0.8510
          0.1333	0.3961	0.5216	0.9255
          0.2000	0.4824	0.6235	0.9765
          0.2667	0.5765	0.7098	1.0000
          0.3333	0.6667	0.7804	0.9922
          0.4000	0.7529	0.8314	0.9608
          0.4667	0.8314	0.8588	0.9020
          0.5333	0.8980	0.8471	0.8196
          0.6000	0.9490	0.7961	0.7176
          0.6667	0.9686	0.7216	0.6118
          0.7333	0.9647	0.6275	0.5059
          0.8000	0.9333	0.5216	0.4078
          0.8667	0.8784	0.3961	0.3098
          0.9333	0.8000	0.2510	0.2235
          1.0000	0.7059	0.0157	0.1490];
  mymap = interpColormapPoints(xrgb,'linear',numcolors);
end

function mymap = fast(numcolors)
  xrgb = [0.0000	0.0549	0.0549	0.4706
          0.1700	0.2431	0.4588	0.8118
          0.3000	0.3569	0.7451	0.9529
          0.4300	0.6863	0.9294	0.9176
          0.5000	0.8980	0.9451	0.7686
          0.5900	0.9569	0.8353	0.5098
          0.7100	0.9294	0.6196	0.3137
          0.8500	0.8000	0.3529	0.1608
          1.0000	0.5882	0.0784	0.1176];
  mymap = interpColormapPoints(xrgb,'linear',numcolors);
end

function mymap = robot(numcolors)
  xrgb = [0.0000  0.3412  0.0667  0.6392
          0.0909  0.2667  0.2157  0.9333
          0.1818  0.2510  0.4353  1.0000
          0.2727  0.2510  0.6706  1.0000
          0.3636  0.4471  0.8235  1.0000
          0.4545  0.7490  0.9412  1.0000
          0.5455  1.0000  0.9412  0.7490
          0.6364  1.0000  0.8235  0.4471
          0.7273  1.0000  0.6510  0.2078
          0.8182  1.0000  0.3569  0.0902
          0.9091  0.9647  0.1059  0.0000
          1.0000  0.8118  0.0314  0.0000];
  mymap = interpColormapPoints(xrgb,'linear',numcolors);
end

function mymap = ultra(numcolors)
  xrgb = [0.0000  0.0784  0.0000  0.5882
          0.0667  0.1882  0.0784  0.8510
          0.1333  0.2588  0.3176  0.9647
          0.2000  0.2510  0.4824  1.0000
          0.2667  0.2510  0.6549  1.0000
          0.3333  0.3804  0.7725  1.0000
          0.4000  0.5686  0.8706  1.0000
          0.4667  0.7843  0.9412  0.9647
          0.5333  0.9647  0.9412  0.7843
          0.6000  1.0000  0.8706  0.5686
          0.6667  1.0000  0.7647  0.3686
          0.7333  1.0000  0.6314  0.2000
          0.8000  1.0000  0.4157  0.1137
          0.8667  0.9804  0.2235  0.0431
          0.9333  0.9255  0.0863  0.0000
          1.0000  0.8118  0.0314  0.0000];
  mymap = interpColormapPoints(xrgb,'linear',numcolors);
end

function mymap = adina(numcolors)
  xrgb = [0.0000	0.5020	0.0000	1.0000
          0.0667	0.1647	0.0000	1.0000
          0.1333	0.0000	0.1647	1.0000
          0.2000	0.0000	0.5020	1.0000
          0.2667	0.0000	0.8314	1.0000
          0.3333	0.0000	1.0000	0.8314
          0.4000	0.0000	1.0000	0.5020
          0.4667	0.0000	1.0000	0.1647
          0.5333	0.1647	1.0000	0.0000
          0.6000	0.5020	1.0000	0.0000
          0.6667	0.8314	1.0000	0.0000
          0.7333	1.0000	0.8314	0.0000
          0.8000	1.0000	0.5020	0.0000
          0.8667	1.0000	0.1647	0.0000
          0.9333	1.0000	0.0000	0.1647
          1.0000	1.0000	0.0000	0.5020];
  mymap = interpColormapPoints(xrgb,'linear',numcolors);
end

function mymap = adina2(numcolors)
  xrgb = [0.0000	0.1647	0.0000	1.0000
          0.0769	0.0000	0.1647	1.0000
          0.1538	0.0000	0.5020	1.0000
          0.2308	0.0000	0.8314	1.0000
          0.3077	0.0000	1.0000	0.8314
          0.3846	0.0000	1.0000	0.5020
          0.4615	0.0000	1.0000	0.1647
          0.5385	0.1647	1.0000	0.0000
          0.6154	0.5020	1.0000	0.0000
          0.6923	0.8314	1.0000	0.0000
          0.7692	1.0000	0.8314	0.0000
          0.8462	1.0000	0.5020	0.0000
          0.9231	1.0000	0.1647	0.0000
          1.0000	1.0000	0.0000	0.1647];
  mymap = interpColormapPoints(xrgb,'linear',numcolors);
end

function mymap = vemlab(numcolors)
  xrgb = [0.0000	0.0196	0.1882	0.3804
          0.0667	0.1294	0.4000	0.6745
          0.1333	0.1882	0.4902	0.7255
          0.2000	0.2627	0.5765	0.7647
          0.2667	0.5725	0.7725	0.8706
          0.3333	0.7098	0.8431	0.9137
          0.4000	0.8196	0.8980	0.9412
          0.4667	0.9294	0.9294	0.9412
          0.5333	0.9882	0.9098	0.8824
          0.6000	0.9922	0.8588	0.7804
          0.6667	0.9569	0.6471	0.5098
          0.7333	0.9098	0.5176	0.3961
          0.8000	0.8392	0.3765	0.3020
          0.8667	0.6980	0.0941	0.1686
          0.9333	0.5529	0.0235	0.1333
          1.0000	0.4039	0.0000	0.1216];
  mymap = interpColormapPoints(xrgb,'linear',numcolors);
end

function mymap = watermelon(numcolors)
  xrgb = [0.0000	0.0510	0.4627	0.1608
          0.0313	0.0784	0.5059	0.2275
          0.0625	0.1098	0.5451	0.2902
          0.0938	0.1490	0.5882	0.3529
          0.1250	0.1882	0.6275	0.4157
          0.1563	0.2353	0.6627	0.4745
          0.1875	0.2824	0.6980	0.5373
          0.2188	0.3373	0.7333	0.5961
          0.2500	0.3961	0.7647	0.6510
          0.2813	0.4549	0.7961	0.7020
          0.3125	0.5176	0.8196	0.7490
          0.3438	0.5804	0.8431	0.7882
          0.3750	0.6471	0.8627	0.8275
          0.4063	0.7137	0.8784	0.8549
          0.4375	0.7765	0.8902	0.8784
          0.4688	0.8392	0.8980	0.8941
          0.5000	0.9020	0.9020	0.9020
          0.5313	0.9333	0.8863	0.8510
          0.5625	0.9569	0.8667	0.8000
          0.5938	0.9765	0.8392	0.7451
          0.6250	0.9882	0.8078	0.6902
          0.6563	0.9961	0.7725	0.6314
          0.6875	0.9961	0.7294	0.5725
          0.7188	0.9922	0.6863	0.5176
          0.7500	0.9804	0.6353	0.4588
          0.7813	0.9608	0.5804	0.4000
          0.8125	0.9373	0.5255	0.3451
          0.8438	0.9098	0.4627	0.2941
          0.8750	0.8745	0.4000	0.2392
          0.9063	0.8353	0.3333	0.1922
          0.9375	0.7922	0.2588	0.1451
          0.9688	0.7451	0.1725	0.0980
          1.0000	0.6941	0.0471	0.0549];
  mymap = interpColormapPoints(xrgb,'linear',numcolors);
end

function mymap = darkwatermelon(numcolors)
  xrgb = [0.0000	0.0941	0.3137	0.0902
          0.0313	0.0784	0.3569	0.1529
          0.0625	0.0549	0.4000	0.2157
          0.0938	0.0235	0.4471	0.2824
          0.1250	0.0078	0.4902	0.3529
          0.1563	0.0196	0.5373	0.4275
          0.1875	0.0824	0.5843	0.5020
          0.2188	0.1569	0.6275	0.5725
          0.2500	0.2353	0.6706	0.6431
          0.2813	0.3216	0.7098	0.7098
          0.3125	0.4078	0.7490	0.7686
          0.3438	0.4980	0.7843	0.8196
          0.3750	0.5922	0.8157	0.8588
          0.4063	0.6824	0.8471	0.8902
          0.4375	0.7686	0.8745	0.9137
          0.4688	0.8471	0.8980	0.9216
          0.5000	0.9216	0.9216	0.9216
          0.5313	0.9255	0.9020	0.8549
          0.5625	0.9255	0.8784	0.7843
          0.5938	0.9255	0.8471	0.7137
          0.6250	0.9216	0.8078	0.6431
          0.6563	0.9137	0.7686	0.5725
          0.6875	0.9020	0.7176	0.5020
          0.7188	0.8863	0.6667	0.4353
          0.7500	0.8667	0.6118	0.3686
          0.7813	0.8431	0.5529	0.3059
          0.8125	0.8157	0.4902	0.2510
          0.8438	0.7804	0.4275	0.2000
          0.8750	0.7451	0.3608	0.1490
          0.9063	0.7059	0.2902	0.1098
          0.9375	0.6627	0.2157	0.0706
          0.9688	0.6157	0.1333	0.0392
          1.0000	0.5647	0.0000	0.0196];
  mymap = interpColormapPoints(xrgb,'linear',numcolors);
end

function mymap = polar(numcolors)
  xrgb = [0.0000	0.2235	0.2863	0.6275
          0.0909	0.2745	0.3333	0.6510
          0.1818	0.3490	0.3804	0.6745
          0.2727	0.5176	0.5176	0.7529
          0.3636	0.5843	0.5922	0.7922
          0.4545	0.7922	0.8118	0.8902
          0.5455	0.8824	0.8235	0.8118
          0.6364	0.8471	0.6275	0.6235
          0.7273	0.8627	0.4706	0.4784
          0.8182	0.8941	0.3686	0.3647
          0.9091	0.8706	0.1961	0.1882
          1.0000	0.9294	0.1059	0.1412];
  mymap = interpColormapPoints(xrgb,'linear',numcolors);
end

function mymap = roma(numcolors)
  xrgb = [0.0000	0.1294	0.2510	0.5765
          0.0909	0.1373	0.3373	0.5843
          0.1818	0.2118	0.4627	0.6353
          0.2727	0.2784	0.6118	0.7255
          0.3636	0.4235	0.7333	0.7490
          0.4545	0.6078	0.7725	0.6941
          0.5455	0.7804	0.8157	0.6000
          0.6364	0.7608	0.7529	0.4510
          0.7273	0.6902	0.6196	0.2353
          0.8182	0.6314	0.4941	0.1765
          0.9091	0.5412	0.3333	0.1373
          1.0000	0.4588	0.1412	0.0745];
  mymap = interpColormapPoints(xrgb,'linear',numcolors);
end

function mymap = cork(numcolors)
  xrgb = [0.0000	0.1451	0.0824	0.2588
          0.0909	0.1490	0.2196	0.4000
          0.1818	0.2275	0.3765	0.5216
          0.2727	0.3882	0.5059	0.6157
          0.3636	0.5961	0.6706	0.7373
          0.4545	0.7412	0.7765	0.8039
          0.5455	0.7216	0.7686	0.7294
          0.6364	0.5882	0.7020	0.5922
          0.7273	0.4471	0.6235	0.4627
          0.8182	0.2941	0.5294	0.3176
          0.9091	0.2157	0.4078	0.1922
          1.0000	0.2549	0.3294	0.1490];
  mymap = interpColormapPoints(xrgb,'linear',numcolors);
end

function mymap = simsolid(numcolors)
  xrgb = [0.0000	0.0000	0.3529	1.0000
          0.0667	0.1451	0.5255	1.0000
          0.1333	0.2902	0.6784	0.9490
          0.2000	0.3804	0.8000	0.8745
          0.2667	0.4431	0.8941	0.8588
          0.3333	0.6235	0.9569	0.8510
          0.4000	0.7765	0.9843	0.8549
          0.4667	0.8784	0.9843	0.8667
          0.5333	0.9843	0.9569	0.8275
          0.6000	0.9765	0.9294	0.7020
          0.6667	0.9922	0.8824	0.6196
          0.7333	1.0000	0.7843	0.4784
          0.8000	1.0000	0.6824	0.3686
          0.8667	0.9843	0.5686	0.3216
          0.9333	0.9922	0.4078	0.2039
          1.0000	1.0000	0.0784	0.1020];
  mymap = interpColormapPoints(xrgb,'linear',numcolors);
end

function mymap = lime(numcolors)
  xrgb = [0.0000	0.0392	0.1333	0.4000
          0.0833	0.1333	0.1922	0.5569
          0.1667	0.1294	0.2824	0.6392
          0.2500	0.1294	0.3961	0.6745
          0.3333	0.1059	0.5255	0.7451
          0.4167	0.1569	0.6196	0.7686
          0.5000	0.2588	0.7137	0.7725
          0.5833	0.4196	0.7765	0.7490
          0.6667	0.5725	0.8392	0.7412
          0.7500	0.7412	0.9059	0.7098
          0.8333	0.8745	0.9529	0.7137
          0.9167	0.9373	0.9804	0.7098
          1.0000	1.0000	1.0000	0.8039];
  mymap = interpColormapPoints(xrgb,'linear',numcolors);
end

function mymap = limediv(numcolors)
  xrgb = [0.0000	0.0510	0.1216	0.2549
          0.0625	0.0980	0.1608	0.3176
          0.1250	0.1294	0.1961	0.4471
          0.1875	0.1176	0.2863	0.5961
          0.2500	0.1176	0.4471	0.6314
          0.3125	0.1843	0.5412	0.6627
          0.3750	0.3843	0.7059	0.6902
          0.4375	0.7451	0.8510	0.8039
          0.5000	0.9569	0.9569	0.8941
          0.5625	0.9255	0.8745	0.5961
          0.6250	0.7569	0.7098	0.2235
          0.6875	0.5176	0.6314	0.0431
          0.7500	0.2510	0.5333	0.0784
          0.8125	0.0706	0.4196	0.1882
          0.8750	0.0471	0.3412	0.1686
          0.9375	0.0941	0.2275	0.1333
          1.0000	0.1020	0.1529	0.1098];
  mymap = interpColormapPoints(xrgb,'linear',numcolors);
end

function mymap = spectral(numcolors)
  % ColorBrewer 11-class 'Spectral' diverging map, cool-to-warm (control points
  % are the official ColorBrewer stops, reversed - embedded directly rather
  % than depending on the external cbrewer() function being on the path)
  xrgb = [0.0000	0.3686	0.3098	0.6353
          0.1000	0.1961	0.5333	0.7412
          0.2000	0.4000	0.7608	0.6471
          0.3000	0.6706	0.8667	0.6431
          0.4000	0.9020	0.9608	0.5961
          0.5000	1.0000	1.0000	0.7490
          0.6000	0.9961	0.8784	0.5451
          0.7000	0.9922	0.6824	0.3804
          0.8000	0.9569	0.4275	0.2627
          0.9000	0.8353	0.2431	0.3098
          1.0000	0.6196	0.0039	0.2588];
  mymap = interpColormapPoints(xrgb,'linear',numcolors);
end

function mymap = RdYlBu(numcolors)
  % ColorBrewer 11-class 'RdYlBu' diverging map, cool-to-warm (control points
  % are the official ColorBrewer stops, reversed - embedded directly rather
  % than depending on the external cbrewer() function being on the path)
  xrgb = [0.0000	0.1922	0.2118	0.5843
          0.1000	0.2706	0.4588	0.7059
          0.2000	0.4549	0.6784	0.8196
          0.3000	0.6706	0.8510	0.9137
          0.4000	0.8784	0.9529	0.9725
          0.5000	1.0000	1.0000	0.7490
          0.6000	0.9961	0.8784	0.5647
          0.7000	0.9922	0.6824	0.3804
          0.8000	0.9569	0.4275	0.2627
          0.9000	0.8431	0.1882	0.1529
          1.0000	0.6471	0.0000	0.1490];
  mymap = interpColormapPoints(xrgb,'linear',numcolors);
end