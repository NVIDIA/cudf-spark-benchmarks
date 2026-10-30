WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
TopNations AS (
    SELECT 
        n.n_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS nation_revenue
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
    GROUP BY 
        n.n_name
    ORDER BY 
        nation_revenue DESC
    LIMIT 5
)
SELECT 
    rn.o_orderkey,
    tn.n_name,
    tn.nation_revenue,
    rn.total_revenue
FROM 
    RankedOrders rn
JOIN 
    TopNations tn ON rn.total_revenue > tn.nation_revenue
WHERE 
    rn.revenue_rank = 1
ORDER BY 
    rn.total_revenue DESC
LIMIT 10;
