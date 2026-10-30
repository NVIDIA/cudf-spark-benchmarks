WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
),
SupplierStats AS (
    SELECT 
        s.s_nationkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_nationkey
),
CustomerOrderCount AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    n.n_name,
    COALESCE(coc.order_count, 0) AS customer_order_count,
    COALESCE(ss.total_avail_qty, 0) AS total_avail_qty,
    COALESCE(ss.avg_supply_cost, 0) AS avg_supply_cost,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders
FROM 
    nation n
LEFT JOIN 
    CustomerOrderCount coc ON n.n_nationkey = coc.c_custkey
LEFT JOIN 
    SupplierStats ss ON n.n_nationkey = ss.s_nationkey
LEFT JOIN 
    RankedOrders ro ON ro.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    n.n_name, coc.order_count, ss.total_avail_qty, ss.avg_supply_cost
ORDER BY 
    n.n_name;