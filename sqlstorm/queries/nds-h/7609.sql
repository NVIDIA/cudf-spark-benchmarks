WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_name
    FROM 
        RankedOrders ro
    WHERE 
        ro.rn <= 5
),
TotalSupplierCost AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * l.l_quantity) AS total_cost
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ro.c_name,
    tsc.total_cost,
    p.p_name,
    p.p_brand
FROM 
    TopOrders ro
LEFT JOIN 
    TotalSupplierCost tsc ON ro.o_orderkey = tsc.ps_partkey
LEFT JOIN 
    part p ON tsc.ps_partkey = p.p_partkey
WHERE 
    tsc.total_cost IS NOT NULL
ORDER BY 
    ro.o_orderdate DESC, ro.o_totalprice DESC;