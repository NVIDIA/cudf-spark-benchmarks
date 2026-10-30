
WITH  sales_rank AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
),
suppliers_greater_avg AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        AVG(ps.ps_supplycost) > (
            SELECT 
                AVG(ps_supplycost)
            FROM 
                partsupp
        )
),
nation_sales AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    n.n_name,
    ns.total_revenue,
    AVG(ps.avg_supplycost) AS avg_supplier_cost,
    sr.c_name AS top_customer,
    sr.total_spent
FROM 
    nation n
LEFT JOIN 
    nation_sales ns ON n.n_nationkey = ns.n_nationkey
LEFT JOIN 
    suppliers_greater_avg ps ON ps.s_suppkey IS NOT NULL
LEFT JOIN 
    sales_rank sr ON sr.rank = 1 AND sr.c_custkey IN (SELECT DISTINCT c.c_custkey FROM customer c)
WHERE 
    ns.total_revenue IS NOT NULL AND ps.avg_supplycost IS NOT NULL
GROUP BY 
    n.n_name, ns.total_revenue, ps.avg_supplycost, sr.c_name, sr.total_spent
ORDER BY 
    ns.total_revenue DESC, avg_supplier_cost DESC;
