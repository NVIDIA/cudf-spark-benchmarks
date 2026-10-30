WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
TopOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        n.n_name
    FROM 
        RankedOrders o
    JOIN 
        nation n ON o.c_nationkey = n.n_nationkey
    WHERE 
        o.OrderRank <= 5
),
SupplierCosts AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * l.l_quantity) AS TotalCost
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        TopOrders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        ps.ps_suppkey
),
MinimumCosts AS (
    SELECT 
        MIN(TotalCost) AS MinCost
    FROM 
        SupplierCosts
)
SELECT 
    s.s_name,
    s.s_acctbal,
    sc.TotalCost,
    mc.MinCost
FROM 
    supplier s
JOIN 
    SupplierCosts sc ON s.s_suppkey = sc.ps_suppkey
JOIN 
    MinimumCosts mc ON sc.TotalCost = mc.MinCost
ORDER BY 
    s.s_name;
