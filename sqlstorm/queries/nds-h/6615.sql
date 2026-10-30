WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_suppkey
),
TopSuppliers AS (
    SELECT 
        s_suppkey,
        SUM(total_available) AS total_qty,
        AVG(avg_supply_cost) AS avg_cost_per_supplier
    FROM 
        SupplierStats
    GROUP BY 
        s_suppkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders,
    SUM(ts.total_qty) AS total_supplied_qty,
    AVG(ts.avg_cost_per_supplier) AS average_supplier_cost,
    COUNT(DISTINCT ro.c_nationkey) AS total_nations_involved
FROM 
    RankedOrders ro
JOIN 
    nation n ON ro.c_nationkey = n.n_nationkey
JOIN 
    TopSuppliers ts ON ro.o_orderkey IN (SELECT l_orderkey FROM lineitem WHERE l_partkey IN (SELECT ps_partkey FROM partsupp))
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    ro.order_rank <= 10
GROUP BY 
    r.r_name
ORDER BY 
    total_orders DESC, total_supplied_qty DESC;
