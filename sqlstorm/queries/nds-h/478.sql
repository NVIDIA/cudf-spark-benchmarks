WITH SupplierOrders AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        RANK() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name
), RankedSuppliers AS (
    SELECT 
        s.*,
        so.total_sales,
        so.order_count,
        so.sales_rank
    FROM 
        supplier s
    LEFT JOIN 
        SupplierOrders so ON s.s_suppkey = so.s_suppkey
), NationalSupplierStats AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT rs.s_suppkey) AS unique_suppliers,
        SUM(COALESCE(rs.total_sales, 0)) AS total_sales,
        AVG(COALESCE(rs.order_count, 0)) AS avg_orders_per_supplier
    FROM 
        nation n
    LEFT JOIN 
        RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey
    GROUP BY 
        n.n_name
)

SELECT 
    ns.n_name,
    ns.unique_suppliers,
    ns.total_sales,
    ns.avg_orders_per_supplier,
    CASE 
        WHEN ns.total_sales > 100000 THEN 'High'
        WHEN ns.total_sales BETWEEN 50000 AND 100000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM 
    NationalSupplierStats ns
WHERE 
    ns.total_sales IS NOT NULL
ORDER BY 
    ns.total_sales DESC;
