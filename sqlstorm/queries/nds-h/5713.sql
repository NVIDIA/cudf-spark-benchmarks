WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
TopNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        n.n_nationkey, n.n_name
    ORDER BY 
        total_revenue DESC
    LIMIT 5
)
SELECT 
    r.r_name,
    r.r_comment,
    tn.total_revenue,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders,
    AVG(ro.o_totalprice) AS avg_order_value
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    TopNations tn ON n.n_nationkey = tn.n_nationkey
LEFT JOIN 
    RankedOrders ro ON tn.n_nationkey = ro.o_orderkey
GROUP BY 
    r.r_name, r.r_comment, tn.total_revenue
ORDER BY 
    tn.total_revenue DESC, total_orders DESC;