WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rnk
    FROM 
        part p
    WHERE 
        LENGTH(p.p_name) > 10 AND 
        p.p_retailprice > 50.00
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        s.s_acctbal,
        s.s_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal < (
            SELECT AVG(s2.s_acctbal)
            FROM supplier s2
        )
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    fs.s_name,
    fs.nation_name,
    fs.s_acctbal
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    FilteredSuppliers fs ON ps.ps_suppkey = fs.s_suppkey
WHERE 
    rp.rnk <= 5
ORDER BY 
    rp.p_brand, rp.p_retailprice DESC;
