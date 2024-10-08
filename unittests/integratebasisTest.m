domainNames = {'npacific', 'indian'};
incs = [60, 90];
bufs = [0, 1];
L = 18;

for iDom = 1:length(domainNames)
    domainName = domainNames{iDom};

    for iInc = 1:length(incs)
        inc = incs(iInc);

        for iBuf = 1:length(bufs)
            buf = bufs(iBuf);
            domain = GeoDomain(domainName, "Buffer", buf, "Inclination", inc);

            [G, V] = glmalpha_new(domain, L);

            I0 = integratebasis(G, domain.Lonlat);
            I = integratebasis_new(G, domain, "ForceNew", true);

            assert(isequal(I0, I))
        end

    end

end
