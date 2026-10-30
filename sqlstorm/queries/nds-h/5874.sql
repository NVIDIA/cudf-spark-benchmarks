
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        s.s_name AS supplier_name,
        c.c_nationkey,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank_order
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
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT RankedOrders.o_orderkey) AS total_orders,
    AVG(RankedOrders.o_totalprice) AS average_order_value
FROM 
    RankedOrders
JOIN 
    nation n ON RankedOrders.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    RankedOrders.rank_order <= 10
GROUP BY 
    r.r_name
ORDER BY 
    total_orders DESC;
