WITH RankedParts AS (
    SELECT 
        P.p_name,
        P.p_brand,
        SUM(PS.ps_availqty) AS total_available,
        COUNT(DISTINCT S.s_suppkey) AS supplier_count,
        ROW_NUMBER() OVER (PARTITION BY P.p_brand ORDER BY SUM(PS.ps_supplycost) DESC) AS brand_rank
    FROM 
        part P
    JOIN 
        partsupp PS ON P.p_partkey = PS.ps_partkey
    JOIN 
        supplier S ON PS.ps_suppkey = S.s_suppkey
    WHERE 
        P.p_retailprice > 50.00
    GROUP BY 
        P.p_name, P.p_brand
),
MaxAvailableParts AS (
    SELECT 
        p_name,
        p_brand,
        total_available,
        supplier_count
    FROM 
        RankedParts 
    WHERE 
        brand_rank = 1
)
SELECT 
    RP.p_name,
    RP.p_brand,
    RP.total_available,
    RP.supplier_count,
    CONCAT('The part ', RP.p_name, ' from brand ', RP.p_brand, ' has ', RP.total_available, ' available units, supplied by ', RP.supplier_count, ' different suppliers.') AS info_message
FROM 
    MaxAvailableParts RP
ORDER BY 
    RP.total_available DESC
LIMIT 10;
