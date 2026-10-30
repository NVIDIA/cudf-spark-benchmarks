WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
),
HighCostBrands AS (
    SELECT 
        p_brand, 
        SUM(TotalCost) AS BrandTotalCost
    FROM 
        RankedParts
    WHERE 
        rnk <= 10
    GROUP BY 
        p_brand
),
NationsSuppliers AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS SupplierCount,
        SUM(s.s_acctbal) AS TotalAccountBalance
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    r.p_brand,
    r.BrandTotalCost,
    ns.n_name,
    ns.SupplierCount,
    ns.TotalAccountBalance
FROM 
    HighCostBrands r
JOIN 
    NationsSuppliers ns ON r.p_brand LIKE '%' || ns.n_name || '%'
ORDER BY 
    r.BrandTotalCost DESC, ns.SupplierCount DESC;
