
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
        COUNT(ps.ps_supplycost) AS supply_count,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_name LIKE '%widget%'
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_container, p.p_retailprice, p.p_comment
),
TopParts AS (
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
        rp.supply_count
    FROM 
        RankedParts rp
    WHERE 
        rp.rank <= 10
)
SELECT 
    tp.p_partkey,
    tp.p_name,
    tp.p_mfgr,
    tp.p_brand,
    tp.p_type,
    tp.p_size,
    tp.p_container,
    tp.p_retailprice,
    tp.p_comment,
    tp.supply_count,
    n.n_name AS supplier_country,
    r.r_name AS region_name,
    COUNT(l.l_orderkey) AS total_orders,
    SUM(l.l_extendedprice) AS total_revenue
FROM 
    TopParts tp
LEFT JOIN 
    supplier s ON tp.p_partkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    lineitem l ON tp.p_partkey = l.l_partkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    tp.p_partkey, tp.p_name, tp.p_mfgr, tp.p_brand, tp.p_type, tp.p_size, tp.p_container, tp.p_retailprice, tp.p_comment, tp.supply_count, n.n_name, r.r_name
ORDER BY 
    tp.p_retailprice DESC;
