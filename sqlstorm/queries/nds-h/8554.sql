
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name AS customer_name,
        s.s_name AS supplier_name,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        o.o_orderstatus = 'F'
),
FilteredOrders AS (
    SELECT 
        r.o_orderkey,
        r.order_rank,
        r.o_orderdate,
        r.o_totalprice,
        r.customer_name,
        r.supplier_name
    FROM 
        RankedOrders r
    WHERE 
        r.order_rank = 1
)
SELECT 
    fo.customer_name,
    fo.o_orderdate,
    SUM(fo.o_totalprice) AS total_revenue,
    COUNT(fo.o_orderkey) AS total_orders,
    AVG(fo.o_totalprice) AS avg_order_value
FROM 
    FilteredOrders fo
GROUP BY 
    fo.customer_name, 
    fo.o_orderdate
HAVING 
    SUM(fo.o_totalprice) > 50000
ORDER BY 
    total_revenue DESC, 
    avg_order_value DESC;
