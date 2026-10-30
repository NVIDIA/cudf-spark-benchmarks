WITH SupplierSales AS (
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
        o.o_orderstatus = 'F'
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighRevenueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_revenue,
        ROW_NUMBER() OVER (ORDER BY ss.total_revenue DESC) AS revenue_rank
    FROM 
        supplier s
    JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    WHERE 
        ss.total_revenue > (SELECT AVG(total_revenue) FROM SupplierSales)
),
RankedSuppliers AS (
    SELECT 
        hrs.s_suppkey,
        hrs.s_name,
        hrs.total_revenue,
        hrs.revenue_rank
    FROM 
        HighRevenueSuppliers hrs
    WHERE 
        hrs.revenue_rank <= 10
)
SELECT 
    rs.s_suppkey,
    rs.s_name,
    rs.total_revenue,
    COALESCE(n.n_name, 'Unknown') AS nation_name,
    CASE 
        WHEN rs.total_revenue > 100000 THEN 'High Performer'
        ELSE 'Regular Supplier' 
    END AS performance_category
FROM 
    RankedSuppliers rs
LEFT JOIN 
    supplier s ON rs.s_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
ORDER BY 
    rs.total_revenue DESC;
