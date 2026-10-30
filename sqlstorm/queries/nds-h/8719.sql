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
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopNations AS (
    SELECT 
        n.n_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
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
        total_revenue DESC
    LIMIT 10
)
SELECT 
    r.r_name AS region_name,
    tn.n_name AS nation_name,
    tn.total_revenue,
    ro.o_orderdate,
    ro.total_revenue AS order_revenue,
    ro.revenue_rank
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    TopNations tn ON n.n_name = tn.n_name
JOIN 
    RankedOrders ro ON tn.total_revenue = ro.total_revenue
WHERE 
    tn.total_revenue > 1000000
ORDER BY 
    r.r_name, tn.total_revenue DESC, ro.o_orderdate;