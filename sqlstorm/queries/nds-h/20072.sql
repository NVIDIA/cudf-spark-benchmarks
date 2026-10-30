
WITH  revenue_summary AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank,
        n.n_nationkey
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate BETWEEN '1995-01-01' AND '1996-01-01'
    GROUP BY 
        c.c_custkey, n.n_nationkey
)
SELECT 
    r_rank.c_custkey AS custkey,
    r_rank.total_revenue,
    r_rank.total_orders,
    COALESCE(pr.s_avg_price, 0) AS avg_supplier_price,
    CASE 
        WHEN r_rank.rank = 1 THEN 'Top Revenue Generator' 
        ELSE 'Regular Revenue Generator' 
    END AS revenue_category
FROM 
    (SELECT c_custkey, total_revenue, total_orders, rank, n_nationkey FROM revenue_summary WHERE rank <= 5) AS r_rank
LEFT JOIN 
    (SELECT 
         ps_suppkey, 
         AVG(ps_supplycost) AS s_avg_price 
     FROM 
         partsupp 
     GROUP BY 
         ps_suppkey) AS pr ON r_rank.c_custkey = pr.ps_suppkey
LEFT JOIN 
    region rg ON r_rank.n_nationkey IS NULL OR rg.r_regionkey = r_rank.n_nationkey
ORDER BY 
    r_rank.total_revenue DESC, r_rank.total_orders DESC;
