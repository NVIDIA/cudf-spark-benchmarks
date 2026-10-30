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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) as price_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > (
            SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_type LIKE '%metal%'
        )
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        ps.ps_comment,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) as cost_rank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 10000
)
SELECT 
    rp.p_mfgr,
    rp.p_name,
    rp.p_container,
    sp.s_name AS supplier_name,
    sp.ps_availqty,
    sp.ps_supplycost,
    ('Price Rank: ' || rp.price_rank || ', Cost Rank: ' || sp.cost_rank) AS rank_info
FROM 
    RankedParts rp
JOIN 
    SupplierParts sp ON rp.p_partkey = sp.ps_partkey
WHERE 
    rp.price_rank <= 5 AND sp.cost_rank <= 3
ORDER BY 
    rp.p_brand, sp.ps_supplycost DESC;
