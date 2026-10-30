
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
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerAnalytics AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name
    FROM 
        SupplierSales s
    WHERE 
        s.total_sales > (SELECT AVG(total_sales) FROM SupplierSales)
),
MergedData AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(h.s_suppkey, -1) AS high_value_suppkey,
        COALESCE(h.s_name, 'N/A') AS high_value_supp_name,
        c.total_spent,
        c.order_count AS customer_order_count,
        COALESCE(s.total_sales, 0) AS supplier_total_sales,
        COALESCE(s.order_count, 0) AS supplier_order_count
    FROM 
        CustomerAnalytics c
    LEFT JOIN 
        HighValueSuppliers h ON h.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p) LIMIT 1)
    LEFT JOIN 
        SupplierSales s ON s.s_suppkey = h.s_suppkey
)

SELECT 
    m.c_custkey,
    m.c_name,
    m.high_value_supp_name,
    m.total_spent,
    m.customer_order_count,
    m.supplier_total_sales,
    m.supplier_order_count
FROM 
    MergedData m
WHERE 
    m.total_spent > 1000 AND 
    (m.supplier_total_sales IS NULL OR m.supplier_total_sales > 5000)
ORDER BY 
    m.total_spent DESC, 
    m.customer_order_count ASC;
