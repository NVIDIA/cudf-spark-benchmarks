WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
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
), TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_sales,
        ss.order_count
    FROM 
        SupplierSales ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    WHERE 
        ss.rn <= 10
), CustomerMetrics AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), SupplierPerformance AS (
    SELECT 
        ts.s_suppkey,
        ts.s_name,
        cm.total_spent,
        cm.order_count,
        CASE 
            WHEN cm.order_count = 0 THEN NULL
            ELSE ROUND(ts.total_sales / NULLIF(cm.order_count, 0), 2)
        END AS avg_sales_per_order
    FROM 
        TopSuppliers ts
    LEFT JOIN 
        CustomerMetrics cm ON ts.order_count = cm.order_count
)
SELECT 
    sp.s_suppkey,
    sp.s_name,
    COALESCE(sp.total_spent, 0) AS total_spent,
    COALESCE(sp.order_count, 0) AS order_count,
    sp.avg_sales_per_order
FROM 
    SupplierPerformance sp
ORDER BY 
    sp.total_spent DESC, sp.order_count DESC;
