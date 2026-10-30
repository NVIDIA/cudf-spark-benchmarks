
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        orders o
),
SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, 
        ps.ps_suppkey
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS TotalSpent,
        COUNT(DISTINCT o.o_orderkey) AS TotalOrders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
NationTotals AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS SupplierCount,
        SUM(s.s_acctbal) AS TotalAccountBalance
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    cs.c_name AS CustomerName,
    ns.SupplierCount,
    ns.TotalAccountBalance,
    rc.TotalCost,
    RANK() OVER (ORDER BY rc.TotalCost DESC) AS CostRank
FROM 
    RankedOrders o
JOIN 
    CustomerSummary cs ON o.o_custkey = cs.c_custkey
LEFT JOIN 
    SupplierCosts rc ON o.o_orderkey = rc.ps_partkey
JOIN 
    NationTotals ns ON cs.TotalOrders > 5 AND ns.SupplierCount > 0
WHERE 
    o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
  AND 
    (rc.TotalCost IS NOT NULL OR rc.TotalCost > 5000)
ORDER BY 
    o.o_orderdate DESC, CostRank;
