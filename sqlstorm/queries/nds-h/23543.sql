WITH SupplierOrders AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_quantity) AS avg_quantity,
        SUM(CASE 
            WHEN l.l_discount > 0.1 THEN l.l_extendedprice * l.l_discount 
            ELSE 0 
        END) AS discount_revenue
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        s.s_acctbal IS NOT NULL
    GROUP BY 
        s.s_suppkey, s.s_name
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        total_revenue,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        SupplierOrders s
    WHERE 
        order_count > 5
)
SELECT 
    r.r_name AS Region_Name,
    n.n_name AS Nation_Name,
    rs.s_name AS Supplier_Name,
    rs.total_revenue,
    CASE 
        WHEN rs.total_revenue IS NULL THEN 'No Revenue'
        WHEN rs.total_revenue < 10000 THEN 'Low Revenue'
        WHEN rs.total_revenue BETWEEN 10000 AND 50000 THEN 'Medium Revenue'
        ELSE 'High Revenue' 
    END AS Revenue_Category
FROM 
    RankedSuppliers rs
INNER JOIN 
    supplier s ON rs.s_suppkey = s.s_suppkey
INNER JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name IS NOT NULL
    OR rs.total_revenue IS NOT NULL
ORDER BY 
    Revenue_Category ASC, rs.total_revenue DESC
LIMIT 100;
