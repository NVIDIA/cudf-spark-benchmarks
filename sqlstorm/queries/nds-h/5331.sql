WITH TotalSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '1996-01-01' AND l.l_shipdate < DATE '1997-01-01'
    GROUP BY 
        p.p_partkey, p.p_name
),
SuppliersInRegion AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        r.r_name = 'ASIA'
),
RankedSales AS (
    SELECT 
        ts.p_partkey, 
        ts.p_name, 
        ts.total_revenue,
        ROW_NUMBER() OVER (ORDER BY ts.total_revenue DESC) AS revenue_rank
    FROM 
        TotalSales ts
    WHERE 
        ts.total_revenue > 10000
)
SELECT 
    rs.p_partkey, 
    rs.p_name,
    rs.total_revenue,
    sir.s_suppkey,
    sir.s_name,
    sir.nation_name,
    sir.region_name
FROM 
    RankedSales rs
JOIN 
    partsupp ps ON rs.p_partkey = ps.ps_partkey
JOIN 
    SuppliersInRegion sir ON ps.ps_suppkey = sir.s_suppkey
WHERE 
    rs.revenue_rank <= 10
ORDER BY 
    rs.total_revenue DESC;