WITH RankedSales AS (
    SELECT 
        ps.ps_partkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        ps.ps_partkey
),
SupplierRegion AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        r.r_name AS region_name,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        supplier s
    LEFT JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name, r.r_name
    HAVING 
        COUNT(o.o_orderkey) > 0
),
TopSuppliers AS (
    SELECT 
        sr.s_suppkey, 
        sr.s_name, 
        sr.total_orders
    FROM 
        SupplierRegion sr
    WHERE 
        sr.total_orders = (SELECT MAX(total_orders) FROM SupplierRegion)
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    COALESCE(rs.total_sales, 0) AS total_sales,
    ts.s_name AS top_supplier_name,
    ts.total_orders AS top_supplier_orders
FROM 
    part p
LEFT JOIN 
    RankedSales rs ON p.p_partkey = rs.ps_partkey AND rs.sales_rank = 1
LEFT JOIN 
    TopSuppliers ts ON 1 = 1
WHERE 
    (p.p_size > 10 AND p.p_retailprice < 100.00) OR (p.p_type LIKE '%screw%' AND p.p_comment IS NOT NULL)
ORDER BY 
    total_sales DESC, 
    p.p_partkey ASC;
