WITH Revenue AS (
    SELECT 
        n.n_name AS nation,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        n.n_name
),
RankedRevenue AS (
    SELECT 
        nation,
        total_revenue,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        Revenue
)
SELECT 
    rr.nation,
    rr.total_revenue,
    rr.revenue_rank,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    COUNT(DISTINCT p.p_partkey) AS part_count
FROM 
    RankedRevenue rr
LEFT JOIN 
    nation n ON rr.nation = n.n_name
LEFT JOIN 
    supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    partsupp ps ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    part p ON p.p_partkey = ps.ps_partkey
WHERE 
    rr.revenue_rank <= 10
GROUP BY 
    rr.nation, rr.total_revenue, rr.revenue_rank
ORDER BY 
    rr.revenue_rank;