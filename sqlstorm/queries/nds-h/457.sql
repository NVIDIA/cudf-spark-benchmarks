
WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        n.n_name AS nation,
        ss.s_suppkey,
        ss.s_name,
        ss.total_revenue,
        ss.total_orders
    FROM 
        SupplierSales ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        ss.revenue_rank <= 5
),
SalesSummary AS (
    SELECT 
        nation,
        SUM(total_revenue) AS total_nation_revenue,
        AVG(total_orders) AS avg_orders_per_supplier
    FROM 
        TopSuppliers
    GROUP BY 
        nation
)
SELECT 
    r.r_name AS region,
    COALESCE(s.total_nation_revenue, 0) AS total_revenue,
    COALESCE(s.avg_orders_per_supplier, 0) AS avg_orders,
    CASE 
        WHEN COALESCE(s.total_nation_revenue, 0) > 100000 THEN 'High'
        WHEN COALESCE(s.total_nation_revenue, 0) BETWEEN 50000 AND 100000 THEN 'Moderate'
        ELSE 'Low'
    END AS revenue_category
FROM 
    region r
LEFT JOIN 
    SalesSummary s ON r.r_name = s.nation
ORDER BY 
    total_revenue DESC, r.r_name;
