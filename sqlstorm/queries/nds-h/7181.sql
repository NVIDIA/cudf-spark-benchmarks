
WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1996-01-01' AND '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name
),
top_customers AS (
    SELECT 
        r.o_orderdate,
        r.o_orderkey,
        c.c_name,
        r.total_revenue
    FROM 
        ranked_orders r
    JOIN 
        customer c ON r.o_orderkey = c.c_custkey
    WHERE 
        r.revenue_rank <= 10
)
SELECT 
    tc.o_orderdate,
    tc.c_name,
    tc.total_revenue,
    p.p_name,
    p.p_brand,
    p.p_retailprice
FROM 
    top_customers tc
JOIN 
    lineitem l ON tc.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
ORDER BY 
    tc.total_revenue DESC, tc.o_orderdate;
