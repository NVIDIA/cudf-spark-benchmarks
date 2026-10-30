WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
high_revenue_orders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.total_revenue,
        ROW_NUMBER() OVER (ORDER BY ro.total_revenue DESC) AS revenue_rank
    FROM 
        ranked_orders ro
    WHERE 
        ro.order_rank = 1
)
SELECT 
    hro.o_orderkey,
    hro.o_orderdate,
    hro.total_revenue,
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name
FROM 
    high_revenue_orders hro
JOIN 
    lineitem l ON hro.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON hro.o_orderkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    hro.total_revenue > 10000.00
ORDER BY 
    hro.total_revenue DESC, hro.o_orderdate ASC
LIMIT 100;
