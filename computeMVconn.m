function [MVconn,MVconn_null] = computeMVconn(X,Y,opt)

if ~isfield(opt,'nRandomisation')
    opt.nRandomisation = 1;
end

nSub = length(X);

% Calculate connectivity on data given
for s=1:nSub
    if ~isfield(opt,'segleng') 
        [mvpd(s,1),lprd(s,1),fc(s,1),fc_svd(s,1)] = data2mvpd_lprd_fc(X{s},Y{s},opt); 
        [dcor(s,1),dcor_u(s,1)] = data2dCor(X{s},Y{s},opt);
        [rc(s,1),~] = data2rc(X{s},Y{s},'Correlation');
    else
        [mim(s,1),imcoh(s,1),imcoh_svd(s,1)] = data2mim(X{s},Y{s},opt);
    end
end

% Calculate connectivity when X and Y independent random noise (since
% some connectivity measures, eg dCor, not bounded by 0 or -1)
bmvpd      = NaN(nSub,opt.nRandomisation);
blprd      = NaN(nSub,opt.nRandomisation);
bfc        = NaN(nSub,opt.nRandomisation);
bfc_svd    = NaN(nSub,opt.nRandomisation);
bdcor      = NaN(nSub,opt.nRandomisation);
brc        = NaN(nSub,opt.nRandomisation);
bmim       = NaN(nSub,opt.nRandomisation);
bimcoh     = NaN(nSub,opt.nRandomisation);
bimcoh_svd = NaN(nSub,opt.nRandomisation);

if opt.nRandomisation == 1 %if only one, then don't bother with parfor like below
    if nSub < 20
        warning('May not be sufficient subjects/randomisations to estimate null properly')
    end
    iter = 1;
    for s=1:nSub % Ensure reasonably accurate estimate
        bX = {}; bY = {};
        for r=1:length(X{s})
            bX{r} = X{s}{r}(randperm(size(X{s}{r},1)),:);
            bY{r} = Y{s}{r}(randperm(size(Y{s}{r},1)),:);
        end
        if ~isfield(opt,'segleng')
            [bmvpd(s,iter),blprd(s,iter),bfc(s,iter),bfc_svd(s,iter)] = data2mvpd_lprd_fc(bX,bY,opt);
            [bdcor(s,iter),bdcor_u(s,iter)] = data2dCor(bX,bY,opt);
            [brc(s,iter),~] = data2rc(bX,bY,'Correlation');
        else
            [bmim(s,iter),bimcoh(s,iter),bimcoh_svd(s,iter)] = data2mim(bX,bY,opt);
        end
    end
elseif opt.nRandomisation > 1
    for s=1:nSub % Ensure reasonably accurate estimate
        fprintf('null subject %d from %d \n',s,nSub)
        parfor iter = 1:opt.nRandomisation
            bX = {}; bY = {};
            for r=1:length(X{s})
                bX{r} = X{s}{r}(randperm(size(X{s}{r},1)),:);
                bY{r} = Y{s}{r}(randperm(size(Y{s}{r},1)),:);
            end
            if ~isfield(opt,'segleng')
                [tmp_bmvpd{iter},tmp_blprd{iter},tmp_bfc{iter},tmp_bfc_svd{iter}] = data2mvpd_lprd_fc(bX,bY,opt);
                [tmp_bdcor{iter},~] = data2dCor(bX,bY,opt);
                [tmp_brc{iter},~] = data2rc(bX,bY,'Correlation');
            else
                [tmp_bmim{iter},tmp_bimcoh{iter},tmp_bimcoh_svd{iter}] = data2mim(bX,bY,opt);
            end
        end
        if ~isfield(opt,'segleng')
            bmvpd(s,:) = cat(2,tmp_bmvpd{:});
            blprd(s,:) = cat(2,tmp_blprd{:});
            bfc(s,:) = cat(2,tmp_bfc{:});
            bfc_svd(s,:) = cat(2,tmp_bfc_svd{:});
            bdcor(s,:) = cat(2,tmp_bdcor{:});
            brc(s,:) = cat(2,tmp_brc{:});
        else
            bmim(s,:) = cat(2,tmp_bmim{:});
            bimcoh(s,:) = cat(2,tmp_bimcoh{:});
            bimcoh_svd(s,:) = cat(2,tmp_bimcoh_svd{:});
        end
    end
end
fprintf('\n')

if ~isfield(opt,'segleng')
    MVconn.FC = fc;
    MVconn.FCSVD = fc_svd;
    MVconn.MVPD = mvpd;
    MVconn.LPRD = lprd;
    MVconn.dCor = dcor;
    MVconn.RCA = rc;
else
    MVconn.MIM = mim;
    MVconn.ImCoh = imcoh;
    MVconn.ImCohPC = imcoh_svd;
end

if ~isfield(opt,'segleng')
    MVconn_null.FC = mean(bfc,2);
    MVconn_null.FCSVD = mean(bfc_svd,2);
    MVconn_null.MVPD = mean(bmvpd,2);
    MVconn_null.LPRD = mean(blprd,2);
    MVconn_null.dCor = mean(bdcor,2);
    MVconn_null.RCA = mean(brc,2);
else
    MVconn_null.MIM = mean(bmim,2);
    MVconn_null.ImCoh = mean(bimcoh,2);
    MVconn_null.ImCohSVD = mean(bimcoh_svd,2);
end

return
