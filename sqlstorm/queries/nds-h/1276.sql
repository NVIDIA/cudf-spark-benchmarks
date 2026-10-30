WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O'
),
SuppliersWithPartCount AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS PartCount
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
NationalSales AS (
    SELECT 
        n.n_name AS Nation,
        SUM(o.o_totalprice) AS TotalSales
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_name
),
SalesRank AS (
    SELECT 
        Nation,
        TotalSales,
        RANK() OVER (ORDER BY TotalSales DESC) AS SalesRank
    FROM 
        NationalSales
)
SELECT 
    p.p_name,
    p.p_brand,
    COALESCE(swc.PartCount, 0) AS SupplierCount,
    ns.Nation,
    ns.TotalSales,
    CASE 
        WHEN sr.SalesRank <= 3 THEN 'Top Nation'
        ELSE 'Other Nation'
    END AS RankCategory,
    ROW_NUMBER() OVER (PARTITION BY ns.Nation ORDER BY p.p_retailprice DESC) AS PartRank
FROM 
    part p
LEFT JOIN 
    SuppliersWithPartCount swc ON swc.PartCount > 0 
LEFT JOIN 
    NationalSales ns ON true
LEFT JOIN 
    SalesRank sr ON ns.Nation = sr.Nation
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size > 1)
    AND p.p_comment LIKE '%fragile%'
ORDER BY 
    ns.Nation, p.p_brand, PartRank;
