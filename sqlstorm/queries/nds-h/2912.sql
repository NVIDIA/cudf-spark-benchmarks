WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON l.l_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s_suppkey, 
        s_name
    FROM 
        SupplierSales
    WHERE 
        sales_rank <= 10
),
CustomerRegion AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        n.n_name AS region_name
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
)
SELECT 
    cr.region_name,
    ts.s_name,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM 
    TopSuppliers ts
LEFT JOIN 
    lineitem l ON l.l_suppkey = ts.s_suppkey
LEFT JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
JOIN 
    CustomerRegion cr ON o.o_custkey = cr.c_custkey
WHERE 
    o.o_orderstatus = 'O' AND 
    l.l_shipdate >= '1997-01-01' 
GROUP BY 
    cr.region_name, ts.s_name
ORDER BY 
    cr.region_name, total_revenue DESC
LIMIT 100;