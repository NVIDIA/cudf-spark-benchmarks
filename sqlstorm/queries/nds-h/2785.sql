WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
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
        AND l.l_shipdate >= '1996-01-01' 
    GROUP BY 
        s.s_suppkey, s.s_name
),
RankedSupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.total_sales,
        s.order_count,
        RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM 
        SupplierSales s
),
TopSuppliers AS (
    SELECT 
        rss.s_suppkey,
        rss.s_name,
        rss.total_sales,
        rss.order_count
    FROM 
        RankedSupplierSales rss
    WHERE 
        rss.sales_rank <= 10
)
SELECT 
    t.s_suppkey,
    t.s_name,
    COALESCE(SUM(ps.ps_availqty), 0) AS total_available_qty,
    CASE 
        WHEN t.order_count = 0 THEN 'No Orders'
        ELSE CONCAT('Orders:', t.order_count)
    END AS order_info
FROM 
    TopSuppliers t
LEFT JOIN 
    partsupp ps ON t.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
GROUP BY 
    t.s_suppkey, t.s_name, t.order_count
ORDER BY 
    t.s_suppkey;