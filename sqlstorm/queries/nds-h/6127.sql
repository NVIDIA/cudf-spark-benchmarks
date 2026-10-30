WITH summary AS (
    SELECT 
        n.n_name AS nation,
        r.r_name AS region,
        SUM(ps.ps_supplycost * l.l_quantity) AS total_cost,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        n.n_name, r.r_name
)
SELECT 
    nation,
    region,
    total_cost,
    order_count,
    RANK() OVER (PARTITION BY region ORDER BY total_cost DESC) AS cost_rank
FROM 
    summary
WHERE 
    total_cost > 0
ORDER BY 
    region, total_cost DESC;