WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
), 
SupplierStats AS (
    SELECT 
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        COUNT(DISTINCT ps.ps_partkey) AS UniqueParts,
        AVG(s.s_acctbal) AS AvgAcctBalance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_nationkey
), 
PartSales AS (
    SELECT 
        p.p_partkey,
        SUM(l.l_quantity) AS TotalSold,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey
)
SELECT 
    r.r_name,
    COALESCE(SUM(ss.TotalCost), 0) AS TotalSupplierCost,
    COALESCE(SUM(ps.TotalRevenue), 0) AS TotalPartRevenue,
    COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
    MAX(o.o_orderdate) AS LastOrderDate
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    SupplierStats ss ON n.n_nationkey = ss.s_nationkey
LEFT JOIN 
    PartSales ps ON ps.TotalSold > 0
LEFT JOIN 
    RankedOrders o ON o.o_orderkey = n.n_nationkey
WHERE 
    r.r_name IS NOT NULL 
    AND (r.r_comment NOT LIKE '%test%' OR r.r_comment IS NULL)
GROUP BY 
    r.r_name
HAVING 
    SUM(ss.TotalCost) IS NOT NULL 
    OR COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY 
    TotalSupplierCost DESC, 
    TotalPartRevenue DESC
LIMIT 10;