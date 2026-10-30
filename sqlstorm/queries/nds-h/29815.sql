WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY LENGTH(p.p_name) DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_size > 10 AND 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
), 
SupplierComments AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_comment,
        REGEXP_REPLACE(s.s_comment, '[^A-Za-z0-9]', '', 'g') AS cleaned_comment
    FROM 
        supplier s
    WHERE 
        LENGTH(s.s_comment) > 50
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_retailprice,
    sc.s_name,
    sc.cleaned_comment
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    SupplierComments sc ON ps.ps_suppkey = sc.s_suppkey
WHERE 
    rp.rn = 1 
ORDER BY 
    rp.p_retailprice DESC, 
    sc.cleaned_comment ASC
LIMIT 100;
