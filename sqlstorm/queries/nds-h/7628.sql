WITH TotalSales AS (
    SELECT 
        p.p_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        n.n_regionkey = (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'AMERICA')
        AND l.l_shipdate >= DATE '1997-01-01'
        AND l.l_shipdate < DATE '1997-12-31'
    GROUP BY 
        p.p_partkey
),
RankedSales AS (
    SELECT 
        p.p_name,
        p.p_brand,
        p.p_type,
        ts.total_revenue,
        RANK() OVER (ORDER BY ts.total_revenue DESC) AS revenue_rank
    FROM 
        TotalSales ts
    JOIN 
        part p ON ts.p_partkey = p.p_partkey
)
SELECT 
    r.revenue_rank,
    r.p_name,
    r.p_brand,
    r.p_type,
    r.total_revenue
FROM 
    RankedSales r
WHERE 
    r.revenue_rank <= 10
ORDER BY 
    r.revenue_rank;