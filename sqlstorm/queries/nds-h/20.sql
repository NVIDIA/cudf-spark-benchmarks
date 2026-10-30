WITH SupplierOrders AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
), NationalRevenue AS (
    SELECT 
        n.n_nationkey,
        SUM(so.total_revenue) AS nation_revenue
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        SupplierOrders so ON s.s_suppkey = so.s_suppkey
    GROUP BY 
        n.n_nationkey
), MaxRevenue AS (
    SELECT 
        n.n_name,
        nr.nation_revenue,
        RANK() OVER (ORDER BY nr.nation_revenue DESC) AS revenue_rank
    FROM 
        NationalRevenue nr
    JOIN 
        nation n ON nr.n_nationkey = n.n_nationkey
)
SELECT 
    m.n_name AS nation,
    m.nation_revenue AS total_revenue,
    CASE 
        WHEN m.revenue_rank <= 5 THEN 'Top 5'
        ELSE 'Other'
    END AS revenue_category
FROM 
    MaxRevenue m
WHERE 
    (m.nation_revenue IS NOT NULL AND m.nation_revenue > 0)
ORDER BY 
    m.revenue_rank;