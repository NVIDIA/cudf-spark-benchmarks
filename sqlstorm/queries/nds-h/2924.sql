WITH SupplierOrderDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sd.total_revenue,
        sd.order_count
    FROM 
        SupplierOrderDetails sd
    JOIN 
        supplier s ON sd.s_suppkey = s.s_suppkey
    WHERE 
        sd.rn <= 5
)
SELECT 
    t.s_suppkey,
    t.s_name,
    t.total_revenue,
    t.order_count,
    COALESCE((SELECT AVG(total_revenue) FROM TopSuppliers WHERE total_revenue < t.total_revenue), 0) AS avg_lower_revenue,
    CASE 
        WHEN t.order_count > 10 THEN 'High'
        WHEN t.order_count BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low'
    END AS order_category
FROM 
    TopSuppliers t
LEFT JOIN 
    region r ON t.s_suppkey = r.r_regionkey
WHERE 
    r.r_name IS NOT NULL OR t.total_revenue > 10000
ORDER BY 
    t.total_revenue DESC;
