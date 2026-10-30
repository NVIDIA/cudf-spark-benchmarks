WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
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
    WHERE 
        l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        ss.total_value,
        ss.order_count
    FROM 
        supplier s
    JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    WHERE 
        ss.sales_rank <= 5
)
SELECT 
    ts.s_name,
    COALESCE(ts.total_value, 0) AS total_sales,
    ts.order_count,
    p.p_name,
    p.p_retailprice,
    CASE 
        WHEN ts.order_count > 10 THEN 'High Volume'
        WHEN ts.order_count BETWEEN 5 AND 10 THEN 'Moderate Volume'
        ELSE 'Low Volume'
    END AS volume_category
FROM 
    TopSuppliers ts
LEFT JOIN 
    partsupp ps ON ts.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    p.p_size >= 10 AND 
    (p.p_brand = 'Brand#43' OR p.p_brand IS NULL)
ORDER BY 
    total_sales DESC, 
    ts.s_name;