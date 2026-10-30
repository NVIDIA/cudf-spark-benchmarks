
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
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
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        n.n_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000000
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.total_revenue,
    tn.nation_revenue,
    r.revenue_rank
FROM 
    RankedOrders r
JOIN 
    TopNations tn ON r.total_revenue > tn.nation_revenue
WHERE 
    r.revenue_rank <= 10
ORDER BY 
    r.o_orderdate DESC, r.total_revenue DESC;
