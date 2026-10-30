WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 1 AND 10
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        SUBSTRING(s.s_comment, 1, 50) AS short_comment
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 5000
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        partsupp ps
    JOIN 
        FilteredSuppliers fs ON ps.ps_suppkey = fs.s_suppkey
),
RevenueCalculations AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        sp.ps_availqty,
        sp.ps_supplycost,
        (sp.ps_availqty * (rp.p_retailprice - sp.ps_supplycost)) AS revenue
    FROM 
        RankedParts rp
    JOIN 
        SupplierParts sp ON rp.p_partkey = sp.ps_partkey
    WHERE 
        rp.rn <= 3
)
SELECT 
    rc.p_brand,
    SUM(rc.revenue) AS total_revenue,
    COUNT(DISTINCT rc.p_partkey) AS distinct_parts
FROM 
    RevenueCalculations rc
GROUP BY 
    rc.p_brand
ORDER BY 
    total_revenue DESC;
