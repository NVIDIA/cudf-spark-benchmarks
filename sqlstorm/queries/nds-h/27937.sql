WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 1 AND 15
),
FrequentSuppliers AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        COUNT(DISTINCT ps.ps_suppkey) > 5
),
CustomerRegions AS (
    SELECT 
        c.c_custkey,
        r.r_name AS region_name,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, r.r_name
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_mfgr,
    rp.p_brand,
    rp.p_type,
    rp.p_retailprice,
    rp.rank,
    cs.region_name,
    cs.order_count,
    fs.supplier_count
FROM 
    RankedParts rp
JOIN 
    FrequentSuppliers fs ON rp.p_partkey = fs.ps_partkey
JOIN 
    CustomerRegions cs ON rp.p_brand LIKE '%' || cs.region_name || '%'
WHERE 
    rp.rank <= 10
ORDER BY 
    rp.p_retailprice DESC, cs.order_count DESC;
