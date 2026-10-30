
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name
),
RevenueRanked AS (
    SELECT 
        o_orderkey,
        o_orderdate,
        c_name,
        total_revenue,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        RankedOrders
)
SELECT 
    rr.o_orderkey,
    rr.o_orderdate,
    rr.c_name,
    rr.total_revenue,
    r.r_name AS region_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
FROM 
    RevenueRanked rr
JOIN 
    lineitem l ON rr.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    rr.revenue_rank <= 10
GROUP BY 
    rr.o_orderkey, rr.o_orderdate, rr.c_name, rr.total_revenue, r.r_name
ORDER BY 
    rr.total_revenue DESC;
