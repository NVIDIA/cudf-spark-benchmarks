WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        s.s_name AS supplier_name,
        r.r_name AS region_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
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
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
        AND o.o_orderstatus = 'O'
),
TopOrders AS (
    SELECT 
        order_rank,
        o_orderkey,
        o_orderdate,
        o_totalprice,
        c_name,
        supplier_name,
        region_name
    FROM 
        RankedOrders
    WHERE 
        order_rank <= 5
)
SELECT 
    region_name,
    COUNT(*) AS total_orders,
    SUM(o_totalprice) AS total_revenue,
    AVG(o_totalprice) AS average_order_value
FROM 
    TopOrders
GROUP BY 
    region_name
ORDER BY 
    total_revenue DESC
LIMIT 10;