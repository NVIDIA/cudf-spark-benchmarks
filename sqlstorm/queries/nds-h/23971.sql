
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS BrandRank
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
),
SupplierStats AS (
    SELECT 
        s.s_nationkey,
        COUNT(DISTINCT s.s_suppkey) AS UniqueSuppliers,
        SUM(s.s_acctbal) AS TotalAccountBalance
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 0
    GROUP BY 
        s.s_nationkey
),
LineItemAnalytics AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
        AVG(l.l_quantity) AS AvgQuantity,
        COUNT(DISTINCT l.l_partkey) AS DistinctParts
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    n.n_name AS NationName,
    COALESCE(ss.UniqueSuppliers, 0) AS SupplierCount,
    COALESCE(ps.TotalAccountBalance, 0) AS TotalSupplierBalance,
    COALESCE(SUM(la.TotalRevenue), 0) AS TotalRevenue,
    COALESCE(AVG(la.AvgQuantity), 0) AS AvgLineQuantity
FROM 
    nation n
LEFT JOIN 
    SupplierStats ss ON n.n_nationkey = ss.s_nationkey
LEFT JOIN 
    SupplierStats ps ON n.n_nationkey = ps.s_nationkey
LEFT JOIN 
    LineItemAnalytics la ON la.l_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o 
        WHERE o.o_orderstatus = 'O' AND o.o_orderkey IS NOT NULL )
WHERE 
    n.n_name LIKE '%land%'
GROUP BY 
    n.n_name,
    ss.UniqueSuppliers,
    ps.TotalAccountBalance
HAVING 
    SUM(COALESCE(la.TotalRevenue, 0)) > (SELECT AVG(TotalRevenue) FROM LineItemAnalytics)
ORDER BY 
    n.n_name ASC
LIMIT 10;
