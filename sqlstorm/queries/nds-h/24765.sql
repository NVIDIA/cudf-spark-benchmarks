
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS top_rank,
        NTILE(4) OVER (ORDER BY s.s_acctbal) AS quartile
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
), AggregateOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
), RegionalSales AS (
    SELECT
        r.r_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(a.total_sales) AS total_revenue
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        AggregateOrders a ON o.o_orderkey = a.o_orderkey
    GROUP BY 
        r.r_name
), TopRegions AS (
    SELECT 
        r.r_name,
        rs.order_count,
        rs.total_revenue,
        RANK() OVER (ORDER BY rs.total_revenue DESC) AS revenue_rank
    FROM 
        region r
    JOIN 
        RegionalSales rs ON r.r_name = rs.r_name
)
SELECT 
    ts.r_name,
    COALESCE(ts.total_revenue, 0) AS total_revenue,
    ts.order_count,
    CASE 
        WHEN ts.revenue_rank <= 10 THEN 'Top 10 Regions'
        ELSE 'Other Regions'
    END AS region_category,
    EXISTS (SELECT 1 FROM partsupp ps WHERE ps.ps_availqty > 100) AS has_large_availability
FROM 
    TopRegions ts
RIGHT JOIN 
    RankedSuppliers sup ON ts.order_count >= sup.top_rank
WHERE 
    sup.quartile = 1
ORDER BY 
    total_revenue DESC, ts.r_name
LIMIT 50;
