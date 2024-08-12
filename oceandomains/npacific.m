%% NPACIFIC
% Finds the longitude and latitude coordinates of the North Pacific Ocean.
%
% Syntax
%   XY = npacific(upscale, buf)
%   XY = npacific(upscale, buf, latlim, morebuffers)
%   XY = npacific(__, 'Name', value)
%   [XY, p] = npacific(__)
%
% Input arguments
%   upscale - How many times to upscale the data
%       This option should be used carefully, as spline interpolation do
%       not work well at sharp corners, and the original sampling rate
%       should be sufficient for most applications.
%       The default value is 0 (no upscaling).
%   buffer - The (negative) buffer from the coastlines in degrees
%       The default value is 0 (no buffer).
%   latlim - The latitudes of the polar caps in degrees
%       The inclination angle can be specified as a scalar or a 1-by-2
%       vector.
%       - If a scalar, the inclination angle is applied to both the north
%           and south polar caps.
%       - If a 1-by-2 vector, the first element is the inclination angle of
%           the north polar cap, and the second element is the inclination
%           angle of the south polar cap.
%       The default value is 90 (no polar caps).
%   morebuffers - Additional buffers to apply to the coastlines
%       The additional buffers must be specified as a cell array of
%       domain names and buffer values.
%       The default value is an empty cell array.
%   LonOrigin - The longitude origin of the data
%       The domain will be contained within the range
%       [LonOrigin - 180, LonOrigin + 180].
%       The default value is 180 (i.e. the range of longitude is [0, 360]).
%   ForceNew - Force the function to reload the data
%       The default value is false.
%   BeQuiet - Suppress the output messages
%       The default value is false.
%
% Output arguments
%   XY - Closed-curved coordinates of the domain
%   p - Polygon of the domain boundary
%       Note that this is an ordinary polyshape object, and not a geoshape
%       or geopolyshape.
%   map - Map of the domain boundary
%       When there is no output argument, a quick and dirty map will be
%       displayed.
%
% Examples
%   The 'default' domain used for most applications is given by
%   XY = npacific('Buffer', 1, 'MoreBuffers', {'earthquakes', 10});
%
% Notes
%   The function is written intentionally so that it is compatible with
%   other region functions from slepian_alpha, i.e.
%   XY = npacific(upscale, buf)
%   works as intended.
%
% Data source
%   The coastline data is based on the GSHHG coastline data:
%       Wessel, P., & Smith, W. H. F. (1996).
%       doi: 10.1029/96JB00104
%   The ocean boundaries are based on IHO's 'Limits of oceans and seas':
%       International Hydrographic Organization & Sieger, R. (2012).
%       doi: 10.1594/PANGAEA.777975
%
% See also
%   OCEANPOLY, GSHHSCOASTLINE, BUFFER4OCEANS
%
% Last modified by
%   2024/08/09, williameclee@arizona.edu (@williameclee)

function varargout = npacific(varargin)
    %% Initialisation
    % Suppress warnings
    warning('off', 'MATLAB:polyshape:repairedBySimplify');
    % Parse the inputs
    [upscale, latlim, buf, moreBufs, lonOrigin, ~, ...
         forceNew, saveData, beQuiet] = ...
        parseoceaninputs(varargin);
    oceanParts = ...
        {'North Pacific Ocean, eastern part', ...
     'North Pacific Ocean, western part'};

    %% Check if the data file exists
    [dataFile, ~, dataExists] = oceanfilename(mfilename, ...
        'Upscale', upscale, 'Latlim', latlim, ...
        'Buffer', buf, 'MoreBuffers', moreBufs);

    if dataExists && ~forceNew
        load(dataFile, 'XY', 'p')

        % Make sure the requested data exists
        if exist('XY', 'var') && exist('p', 'var')

            if beQuiet < 2
                fprintf('%s loaded %s\n', upper(mfilename), dataFile)
            end

            varargout = returncoastoutputs(nargout, XY, p);

            return
        end

    end

    %% Compute the ocean boundary
    % Find the ocean boundary (not accounting for the coastlines)
    [oceanPoly, oceanLatlim, oceanLonlim] = oceanpoly( ...
        oceanParts, latlim, lonOrigin, 'BeQuiet', beQuiet);
    % Find the coastline
    [~, coastPoly] = gshhscoastline('l', 'Buffer', buf, ...
        'LatLim', oceanLatlim, 'LonLim', oceanLonlim, ...
        'LonOrigin', lonOrigin, 'BeQuiet', beQuiet);
    % Crop out more buffers
    [~, coastPoly] = buffer4oceans(coastPoly, ...
        'MoreBuffers', moreBufs, 'LonOrigin', lonOrigin);
    % Manually remove small holes
    coastPoly = manualadjustments(coastPoly, buf, moreBufs, lonOrigin);
    % Subtract the land regions from the ocean boundary
    p = subtract(oceanPoly, coastPoly);

    % Turn the polygon into a well-defined curve
    XY = poly2xy(p, upscale);

    %% Save and return data
    varargout = returncoastoutputs(nargout, XY, p);

    if ~saveData
        return
    end

    save(dataFile, 'XY', 'p', '-v7.3')

    if beQuiet < 2
        fprintf('%s saved %s\n', upper(mfilename), dataFile)
    end

end

%% Subfunctions
% Manually remove small holes in the coastline
function coastPoly = manualadjustments(coastPoly, buf, moreBufs, lonOrigin)

    if buf >= 0.5
        coastPoly = addlandregion(coastPoly, ...
            'Latlim', [29, 32; 27, 29; 66, 67; 48.8, 51; ...
               37.5, 40; 8, 14; 22, 25], ...
            'Lonlim', [245.5, 247.5; 247, 250; 190, 193; 140, 142; ...
               119, 121; 121, 125.5; 117, 121], ...
            'LongitudeOrigin', lonOrigin);
    end

    if buf >= 1
        coastPoly = addlandregion(coastPoly, ...
            'Latlim', [58, 61; 38, 39; 22, 24; 9, 11; 3, 4.5], ...
            'Lonlim', [156, 160; 122, 124; 118, 120; 124, 125; 124, 126.9], ...
            'LongitudeOrigin', lonOrigin);

        if any(strcmp(moreBufs, 'earthquakes'))
            coastPoly = addlandregion(coastPoly, ...
                'Latlim', [38, 40; 35, 36], ...
                'Lonlim', [129, 130; 130, 131], ...
                'LongitudeOrigin', lonOrigin);
        end

    end

    if buf >= 1.5
        coastPoly = addlandregion(coastPoly, ...
            'Latlim', [43.5, 46], 'Lonlim', [137, 140], ...
            'LongitudeOrigin', lonOrigin);

    end

    if buf >= 2
        coastPoly = addlandregion(coastPoly, ...
            'Latlim', [37, 43; 3, 4.5; 33, 36], ...
            'Lonlim', [130, 138; 125, 127; 122, 125], ...
            'LongitudeOrigin', lonOrigin);
    end

    if buf >= 3.5
        coastPoly = addlandregion(coastPoly, ...
            'Latlim', [56, 52], 'Lonlim', [148, 152], ...
            'LongitudeOrigin', lonOrigin);
    end

    if buf >= 4
        coastPoly = addlandregion(coastPoly, ...
            'Latlim', [49.5, 52.5], 'Lonlim', [149, 152], ...
            'LongitudeOrigin', lonOrigin);
    end

end
