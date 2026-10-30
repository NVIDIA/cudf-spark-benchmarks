WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) as rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
),
SupplyCost AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    ro.c_name,
    SUM(ro.o_totalprice) AS total_order_value,
    sc.total_supply_cost,
    SUM(ro.o_totalprice) - COALESCE(sc.total_supply_cost, 0) AS profit_margin
FROM 
    RankedOrders ro
LEFT JOIN 
    SupplyCost sc ON ro.o_orderkey = (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'Brand#44') LIMIT 1)
WHERE 
    ro.rank <= 10
GROUP BY 
    ro.c_name, sc.total_supply_cost
ORDER BY 
    profit_margin DESC
LIMIT 10;