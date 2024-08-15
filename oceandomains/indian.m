%% INDIAN
% Finds the longitude and latitude coordinates of the Indian Ocean.
%
% Syntax
%   XY = indian(upscale, buf)
%   XY = indian(upscale, buf, latlim, morebuffers)
%   XY = indian(__, 'Name', value)
%   [XY, p] = indian(__)
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
%   XY = indian('Buffer', 1, 'Latlim', 60, ...
%       'MoreBuffers', {'earthquakes', 10});
%
% Notes
%   The function is written intentionally so that it is compatible with
%   other region functions from slepian_alpha, i.e.
%   XY = indian(upscale, buf)
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
%   2024/08/15, williameclee@arizona.edu (@williameclee)

function varargout = indian(varargin)
    %% Initialisation
    % Suppress warnings
    warning('off', 'MATLAB:polyshape:repairedBySimplify');

    % First check: rotation
    if nargin == 1 && strcmpi(varargin{1}, 'rotated')
        varargout = {false};
        return
    end

    % Parse the inputs
    lonOriginD = 180;
    [upscale, latlim, buf, moreBufs, lonOrigin, ~, ...
         forceNew, saveData, beQuiet] = ...
        parseoceaninputs(varargin, 'DefaultLonOrigin', lonOriginD);
    oceanParts = 'Indian Ocean';

    %% Check if the data file exists
    [dataFile, ~, dataExists] = oceanfilename(mfilename, ...
        'Upscale', upscale, 'LatLim', latlim, ...
        'Buffer', buf, 'MoreBuffers', moreBufs);

    if dataExists && ~forceNew
        load(dataFile, 'XY', 'p')

        % Make sure the requested data exists
        if exist('XY', 'var') && exist('p', 'var')

            if beQuiet < 2
                fprintf('%s loaded %s\n', upper(mfilename), dataFile)
            end

            if lonOrigin ~= lonOriginD
                [Y, X] = flatearthpoly(XY(:, 2), XY(:, 1), lonOrigin);
                p = polyshape(X, Y);
                XY = poly2xy(p);
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
    coastPoly = manualadjustments(coastPoly, buf, lonOrigin);
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
function coastPoly = manualadjustments(coastPoly, buf, lonOrigin)
    coastPoly = addlandregion(coastPoly, ...
        'Latlim', [-16, -15], 'Lonlim', [127, 129], ...
        'LongitudeOrigin', lonOrigin);

    if buf >= 0.5
        coastPoly = addlandregion(coastPoly, ...
            'Latlim', [13, 28; 24, 30; 10, 13; 1, 3.5], ...
            'Lonlim', [34, 45; 45, 56; 43, 45.5; 100, 103], ...
            'LongitudeOrigin', lonOrigin);
    end

    if buf >= 1
        coastPoly = addlandregion(coastPoly, ...
            'Latlim', [10, 14; -9.5, 8; 4, 8], ...
            'Lonlim', [45, 48; 115, 116; 98, 100], ...
            'LongitudeOrigin', lonOrigin);
    end

    if buf >= 1.5
        coastPoly = addlandregion(coastPoly, ...
            'Latlim', [6, 8], 'Lonlim', [97, 99], ...
            'LongitudeOrigin', lonOrigin);
    end

    if buf >= 3.5
        coastPoly = addlandregion(coastPoly, ...
            'Latlim', [-24, -20], 'Lonlim', [34, 40], ...
            'LongitudeOrigin', lonOrigin);
    end

end
