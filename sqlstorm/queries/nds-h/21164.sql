WITH  NationalRevenue AS (
    SELECT 
        n.n_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
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
),
TopRegions AS (
    SELECT 
        r.r_name,
        SUM(NR.total_revenue) AS region_revenue,
        ROW_NUMBER() OVER (ORDER BY SUM(NR.total_revenue) DESC) AS region_rn
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        NationalRevenue NR ON n.n_name = NR.n_name
    GROUP BY 
        r.r_name
)
SELECT 
    TR.r_name, 
    COALESCE(TR.region_revenue, 0) AS revenue,
    CASE 
        WHEN TR.region_rn IS NULL THEN 'Not Ranked'
        ELSE 'Rank ' || TR.region_rn 
    END AS revenue_rank
FROM 
    TopRegions TR
FULL OUTER JOIN 
    (SELECT DISTINCT c_nationkey FROM customer WHERE c_acctbal < 0) AS NegativeBalance ON TR.region_rn IS NULL
WHERE 
    TR.region_revenue > (SELECT AVG(region_revenue) FROM TopRegions WHERE region_revenue IS NOT NULL)
ORDER BY 
    revenue DESC NULLS LAST;
