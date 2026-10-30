WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_type, 
        p.p_size, 
        p.p_container, 
        p.p_retailprice, 
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) as Rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
), 
SupplierCount AS (
    SELECT 
        ps.ps_partkey, 
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    INNER JOIN 
        RankedParts rp ON ps.ps_partkey = rp.p_partkey
    GROUP BY 
        ps.ps_partkey
)

SELECT 
    rp.p_partkey, 
    rp.p_name, 
    rp.p_mfgr, 
    rp.p_brand, 
    rp.p_type, 
    rp.p_size, 
    rp.p_container, 
    rp.p_retailprice, 
    rp.p_comment, 
    sc.supplier_count
FROM 
    RankedParts rp
JOIN 
    SupplierCount sc ON rp.p_partkey = sc.ps_partkey
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.p_brand, 
    rp.p_retailprice DESC;
