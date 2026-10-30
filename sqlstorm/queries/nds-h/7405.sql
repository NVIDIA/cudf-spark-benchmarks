WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) as order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
        AND o.o_orderdate < DATE '1997-12-31'
),
SupplierCosts AS (
    SELECT
        ps.ps_partkey,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_nationkey
),
TotalSales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    JOIN 
        RankedOrders r ON l.l_orderkey = r.o_orderkey
    GROUP BY 
        l.l_partkey
),
SalesAndCost AS (
    SELECT 
        ts.l_partkey,
        ts.total_sales,
        sc.total_supply_cost,
        (ts.total_sales - sc.total_supply_cost) AS profit
    FROM 
        TotalSales ts
    JOIN 
        SupplierCosts sc ON ts.l_partkey = sc.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    sac.total_sales,
    sac.total_supply_cost,
    sac.profit
FROM 
    SalesAndCost sac
JOIN 
    part p ON sac.l_partkey = p.p_partkey
WHERE 
    sac.profit > 0
ORDER BY 
    sac.profit DESC
LIMIT 10;