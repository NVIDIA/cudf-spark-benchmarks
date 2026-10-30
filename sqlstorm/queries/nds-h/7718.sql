WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        o.o_totalprice, 
        o.o_orderdate, 
        o.o_orderpriority, 
        c.c_name AS customer_name, 
        n.n_name AS nation_name, 
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
)
SELECT 
    r.r_name AS region_name, 
    COUNT(DISTINCT ro.customer_name) AS unique_customers, 
    SUM(ro.o_totalprice) AS total_revenue,
    AVG(ro.o_totalprice) AS avg_order_value,
    MAX(ro.o_totalprice) AS max_order_value
FROM 
    RankedOrders ro
JOIN 
    nation n ON n.n_name = ro.nation_name
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    ro.rank <= 5
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue DESC;