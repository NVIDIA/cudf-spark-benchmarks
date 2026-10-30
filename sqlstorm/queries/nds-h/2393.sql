
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS NationRank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
),
LineitemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
        COUNT(l.l_orderkey) AS ItemCount
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.n_name AS Nation,
    COUNT(DISTINCT COALESCE(o.o_orderkey, 0)) AS TotalOrders,
    SUM(COALESCE(ls.TotalRevenue, 0)) AS TotalRevenue,
    AVG(COALESCE(s.s_acctbal, 0)) AS AvgSupplierAcctBal
FROM 
    nation r
LEFT JOIN 
    supplier s ON r.n_nationkey = s.s_nationkey
LEFT JOIN 
    RankedOrders o ON s.s_suppkey = o.o_orderkey
LEFT JOIN 
    LineitemSummary ls ON ls.l_orderkey = o.o_orderkey
LEFT JOIN 
    partsupp ps ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    part p ON p.p_partkey = ps.ps_partkey
GROUP BY 
    r.n_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    TotalRevenue DESC
LIMIT 10;
