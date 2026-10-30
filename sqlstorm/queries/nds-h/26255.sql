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
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        LOWER(p.p_name) LIKE '%steel%'
        AND p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_type = p.p_type)
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        RANK() OVER (ORDER BY s.s_acctbal DESC) AS rank_acctbal
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 10000
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
    si.s_suppkey,
    si.s_name,
    si.rank_acctbal
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    SupplierInfo si ON ps.ps_suppkey = si.s_suppkey
WHERE 
    si.rank_acctbal <= 5
ORDER BY 
    rp.p_type, rp.p_retailprice DESC;
