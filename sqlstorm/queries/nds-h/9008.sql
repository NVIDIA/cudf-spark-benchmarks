WITH RankedSuppliers AS (
    SELECT 
        s_suppkey, 
        s_name, 
        s_nationkey, 
        SUM(ps_supplycost * ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s_nationkey ORDER BY SUM(ps_supplycost * ps_availqty) DESC) AS rank
    FROM 
        supplier 
    JOIN 
        partsupp ON supplier.s_suppkey = partsupp.ps_suppkey 
    GROUP BY 
        s_suppkey, s_name, s_nationkey
),
RecentOrders AS (
    SELECT 
        o_custkey, 
        COUNT(o_orderkey) AS order_count,
        SUM(o_totalprice) AS total_revenue
    FROM 
        orders 
    WHERE 
        o_orderdate >= DATE '1997-01-01'
    GROUP BY 
        o_custkey
)
SELECT 
    c.c_name, 
    r.r_name, 
    rs.s_name AS top_supplier,
    ro.order_count, 
    ro.total_revenue,
    rs.total_supply_cost
FROM 
    customer c
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    RecentOrders ro ON c.c_custkey = ro.o_custkey
LEFT JOIN 
    RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey AND rs.rank = 1
WHERE 
    c.c_acctbal > 10000 
ORDER BY 
    ro.total_revenue DESC NULLS LAST, 
    rs.total_supply_cost DESC NULLS LAST;