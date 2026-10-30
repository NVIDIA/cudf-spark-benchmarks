WITH RankedSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
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
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        r.r_name = 'ASIA'
    AND 
        l.l_shipdate >= DATE '1995-01-01' 
    AND 
        l.l_shipdate <= DATE '1995-12-31'
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    r.p_partkey,
    r.p_name,
    r.revenue
FROM 
    RankedSales r
WHERE 
    r.rank <= 10
ORDER BY 
    r.revenue DESC;