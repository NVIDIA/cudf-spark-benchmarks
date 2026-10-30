WITH summary AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(o.o_totalprice) AS total_revenue,
        AVG(p.p_retailprice) AS avg_part_price,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        n.n_name
)
SELECT 
    nation_name,
    customer_count,
    total_revenue,
    avg_part_price,
    total_quantity
FROM 
    summary
WHERE 
    total_revenue > (SELECT AVG(total_revenue) FROM summary)
ORDER BY 
    total_revenue DESC;