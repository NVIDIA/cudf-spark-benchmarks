WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        c.c_name,
        c.c_nationkey,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
),
ProductSupplierStats AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_availability,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerAverageOrderValue AS (
    SELECT 
        c.c_nationkey,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders,
    SUM(COALESCE(pas.total_availability, 0)) AS total_product_availability,
    AVG(COALESCE(ca.avg_order_value, 0)) AS avg_order_value,
    MAX(ro.o_totalprice) AS max_order_price
FROM 
    RankedOrders ro
JOIN 
    nation n ON ro.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    ProductSupplierStats pas ON ro.o_orderkey = pas.ps_partkey
LEFT JOIN 
    CustomerAverageOrderValue ca ON ro.c_nationkey = ca.c_nationkey
WHERE 
    ro.order_rank <= 10
GROUP BY 
    r.r_name
ORDER BY 
    total_orders DESC, avg_order_value DESC;