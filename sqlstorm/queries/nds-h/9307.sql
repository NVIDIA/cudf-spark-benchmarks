WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
top_orders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.total_revenue
    FROM 
        ranked_orders ro
    WHERE 
        ro.rank <= 10
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.total_revenue,
    c.c_name,
    s.s_name,
    n.n_name
FROM 
    top_orders o
JOIN 
    customer c ON o.o_orderkey = c.c_custkey
JOIN 
    supplier s ON s.s_suppkey = (SELECT ps.ps_suppkey 
                                  FROM partsupp ps 
                                  JOIN part p ON ps.ps_partkey = p.p_partkey 
                                  WHERE ps.ps_availqty > 0 
                                  LIMIT 1)
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
ORDER BY 
    o.total_revenue DESC;
