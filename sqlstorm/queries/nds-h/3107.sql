WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linestatus) AS unique_status_count,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
FilteredOrders AS (
    SELECT 
        od.o_orderkey,
        od.total_revenue,
        od.unique_status_count,
        od.avg_quantity,
        CASE 
            WHEN od.total_revenue > 1000000 THEN 'High'
            WHEN od.total_revenue BETWEEN 500000 AND 1000000 THEN 'Medium'
            ELSE 'Low'
        END AS revenue_category
    FROM 
        OrderDetails od
    WHERE 
        od.avg_quantity > (SELECT AVG(avg_quantity) FROM OrderDetails)
)
SELECT 
    f.o_orderkey,
    f.total_revenue,
    f.unique_status_count,
    f.avg_quantity,
    f.revenue_category,
    COALESCE(rs.s_name, 'No Supplier') AS top_supplier_name
FROM 
    FilteredOrders f
LEFT OUTER JOIN 
    RankedSuppliers rs ON f.o_orderkey = rs.s_suppkey AND rs.rn = 1
WHERE 
    f.revenue_category = 'High'
ORDER BY 
    f.total_revenue DESC
LIMIT 10;
