function [Uval,Vval, Rval, Evalval,Cval,Dval] = VAL_2d3c(X,Y,U,V,R, Eval,C,D,Threshswitch,UODswitch,Bootswitch,extrapeaks,Uthresh,Vthresh,UODwinsize,UODthresh,Bootper,Bootiter,Bootkmax)
% --- Validation Subfunction ---
if extrapeaks
    j=3;
else
    j=1;
end

[X,Y,U,V,R,Eval,C,D] = matrixform_rotation(X,Y,U,V,R, Eval,C,D);

Uval=U(:,:,1);
Vval=V(:,:,1);
Rval = R(:, :, 1);
Evalval=Eval(:,:,1);

if ~isempty(C)
    Cval=C(:,:,1);
    Dval=D(:,:,1);
else
    Cval=[];
    Dval= [];
end
S=size(X);

if Threshswitch || UODswitch
    for i=1:j
        %Thresholding
        if Threshswitch
            [Uval,Vval,Evalval] = Thresh(Uval,Vval,Uthresh,Vthresh,Evalval);
        end

        %Univeral Outlier Detection
        if UODswitch
            t=permute(UODwinsize,[2 3 1]);
            t=t(:,t(1,:)~=0);
            [Uval,Vval,Rval, Evalval] = UOD_rotation(Uval,Vval, Rval, t',UODthresh,Evalval);
        end
%         disp([num2str(sum(sum(Evalval>0))),' bad vectors'])
        %Try additional peaks where validation failed
        if i < j
            Utemp=U(:,:,i+1);Vtemp=V(:,:,i+1);Evaltemp=Eval(:,:,i+1);Ctemp=C(:,:,i+1);Dtemp=D(:,:,i+1);
            Rtemp = R(:, :, i+1);
            Uval(Evalval>0)=Utemp(Evalval>0);
            Vval(Evalval>0)=Vtemp(Evalval>0);
            Rval(Evalval > 0 ) = Rtemp(Evalval > 0);
            Cval(Evalval>0)=Ctemp(Evalval>0);
            Dval(Evalval>0)=Dtemp(Evalval>0); 
            Evalval(Evalval>0)=Evaltemp(Evalval>0);
        end
    end
end

%limit replacement search radius to largest region tested during UOD
maxSearch = floor( (max(UODwinsize(:))-1)/2 );

%replacement
for i=1:S(1)
    for j=1:S(2)
        if Evalval(i,j)>0
            %initialize replacement search size
            q=0;
            s=0;

            %get replacement block with at least 8 valid points, but stop if region grows bigger than UOD test region
            while s==0
                q=q+1;
                Imin = max([i-q 1   ]);
                Imax = min([i+q S(1)]);
                Jmin = max([j-q 1   ]);
                Jmax = min([j+q S(2)]);
                Iind = Imin:Imax;
                Jind = Jmin:Jmax;
                Ublock = Uval(Iind,Jind);
                if q >= maxSearch || length(Ublock(~isnan(Ublock)))>=8 
                    Xblock = X(Iind,Jind)-X(i,j);
                    Yblock = Y(Iind,Jind)-Y(i,j);
                    Vblock = Vval(Iind,Jind);
                    Rblock = Rval(Iind, Jind);
                    s=1;
                end
            end
            
            %distance from erroneous vector
            Dblock = (Xblock.^2+Yblock.^2).^-0.5;
            Dblock(isnan(Ublock))=nan;

            %validated vector
            Uval(i,j) = nansum(nansum(Dblock.*Ublock))/nansum(nansum(Dblock));
            Vval(i,j) = nansum(nansum(Dblock.*Vblock))/nansum(nansum(Dblock));      
            Rval(i, j) = nansum(nansum(Dblock .* Rblock)) / nansum(nansum(Dblock));
        end
    end
end

%clean up any remaining NaNs
Uval(isnan(Uval)) = 0;
Vval(isnan(Vval)) = 0;

end