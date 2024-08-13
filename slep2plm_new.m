%% SLEP2PLM
% Finds the spherical harmonic expansion coefficients of a function whose
% Slepian-basis (in terms of a SINGLE-CAP, potentially rotated Slepian
% basis) expansion coefficients are known.
%
% Syntax
%   [lmcosi, V, N] = slep2plm(falpha, r, L, phi, theta, omega)
%   [lmcosi, V, N] = slep2plm(falpha, domain, L)
%   [lmcosi, V, N] = slep2plm(__, 'Truncation', truncation)
%   [__, MTAP, truncation] = slep2plm(__)
%   slep2plm('demo')
%
% Input arguments
%   falpha - Slepian expansion coefficients
%   r - Radius of the concentration region in degrees
%       The default value is 30 degrees
%   domain - Geographic domain or a latitude-longitude pair
%       - A geographic domain (GeoDomain object).
%       - A string of the domain name.
%       - A cell array of the form {'domain name', buf}.
%       - A N-by-2 matrix of longitude-latitude vertices.
%   L - Bandwidth of the window
%       The default value is 18.
%   phi, theta, omega - Longitude, colatitude, and anticlockwise azimuthal
%       rotation of the centre of the tapers in degrees
%       The default values are 0.
%   truncation - The number of Slepian functions to use in the expansion
%       The default value is the Shannon number N.
%
% Output arguments
%   lmcosi - Standard-type real spherical harmonic expansion coefficients
%   V - Eigenvalues of the Slepian functions
%   N - Shannon number
%   MTAP
%   truncation - The number of Slepian functions used in the expansion
%       The default value is round(N).
%
% Examples
%   The following example demonstrate the use of PLM2SLEP and SLEP2PLM:
%   >>  slep2plm_new('demo')
%
% See also
%   PTOSLEP, GLMALPHA, GLMALPHAPTO, PLM2SLEP, SLEP2XYZ, XYZ2SLEP
%
% Last modified by
%   2024/08/13, williameclee@arizona.edu (@williameclee)
%   2023/10/21, fjsimons@alum.mit.edu (@fjsimons)

function varargout = slep2plm_new(varargin)
    %% Initialisation
    % Add path to the auxiliary functions
    addpath(fullfile(fileparts(mfilename('fullpath')), 'demos'));

    % Demos
    if ischar(varargin{1}) || isstring(varargin{1})
        demoId = varargin{1};

        if ~strcmpi(demoId, 'demo')
            error('Unknown demo name ''%s''', demoId);
        end

        slep2plm_demo(mfilename);
        return
    end

    % Parse inputs
    [falpha, domain, L, phi, theta, omega, truncation] = ...
        parseinputs(varargin{:});

    %% Computing the projection
    % Find the projection of the Slepian basis onto the spherical harmonics
    if phi == 0 && theta == 0 && omega == 0
        % A geographic domain or a latitude-longitude pair
        [G, V, ~, ~, N, ~, MTAP] = glmalpha_new(domain, L);
    else
        % A polar cap
        % Need to get a complete GLMALPHA but for the rotated basis
        % Definitely, 'single-order' has lost its meaning here, but the
        % MTAP will still identify what the order of the unrotated original
        % was
        [G, V, ~, ~, N, ~, MTAP] = ...
            glmalphapto(domain, L, phi, theta, omega);
    end

    % Truncate the expansion
    truncation = conddefval(truncation, round(N));

    % Sort by decreasing eigenvalue, rely on the falphas to be similarly
    % sorted
    [V, vi] = sort(V, 'descend');
    G = G(:, vi);

    if ~isnan(MTAP)
        MTAP = MTAP(vi);
    end

    %% Expansion
    % Get the mapping from LMCOSI into not-block-sorted GLMALPHA
    [~, ~, ~, lmcosi, ~, ~, ~, ~, ~, ronm] = addmon(L);

    % Perform the expansion of the signal into the Slepian basis
    % and stick these coefficients in at the right places
    lmcosi(2 * size(lmcosi, 1) + ronm(1:(L + 1) ^ 2)) = ...
        G(:, 1:truncation) * falpha(1:truncation);

    % Collect output
    varargout = {lmcosi, V, N, MTAP, truncation};
end

%% Subfunctions
function varargout = parseinputs(varargin)
    domainD = 30;
    LD = 18;
    phiD = 0;
    thetaD = 0;
    omegaD = 0;

    p = inputParser;
    addRequired(p, 'falpha', @isnumeric);
    addOptional(p, 'Domain', domainD, ...
        @(x) ischar(x) || iscell(x) || isa(x, "GeoDomain") || ...
        isnumeric(x) || isempty(x));
    addOptional(p, 'L', LD, @(x) isnumeric(x) || isempty(x));
    addOptional(p, 'phi', phiD, @(x) isnumeric(x) || isempty(x));
    addOptional(p, 'theta', thetaD, @(x) isnumeric(x) || isempty(x));
    addOptional(p, 'omega', omegaD, @(x) isnumeric(x) || isempty(x));
    addOptional(p, 'Truncation', [], @(x) isnumeric(x) || isempty(x));

    parse(p, varargin{:});
    falpha = p.Results.falpha(:);

    domain = conddefval(p.Results.Domain, domainD);
    L = conddefval(p.Results.L, LD);
    phi = conddefval(p.Results.phi, phiD);
    theta = conddefval(p.Results.theta, thetaD);
    omega = conddefval(p.Results.omega, omegaD);

    truncation = round(p.Results.Truncation);

    % Convert the domain to a GeoDomain object if applicable
    if ischar(domain) || isstring(domain) && exist(domain, "file")
        domain = GeoDomain(domain);
    elseif iscell(domain) && length(domain) == 2
        domain = ...
            GeoDomain(domain{1}, "Buffer", domain{2});
    elseif iscell(domain) && length(domain) >= 3
        domain = GeoDomain(domain{:});
    end

    varargout = {falpha, domain, L, phi, theta, omega, truncation};
end