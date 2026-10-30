
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
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
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    r.o_orderdate,
    COUNT(DISTINCT r.o_orderkey) AS total_orders,
    COALESCE(SUM(r.total_revenue), 0) AS total_revenue,
    t.n_name,
    t.nation_revenue
FROM 
    RankedOrders r
LEFT JOIN 
    TopNations t ON r.total_revenue = t.nation_revenue
GROUP BY 
    r.o_orderdate, t.n_name, t.nation_revenue
ORDER BY 
    r.o_orderdate ASC, total_revenue DESC;
