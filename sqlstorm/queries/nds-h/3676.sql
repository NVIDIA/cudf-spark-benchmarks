WITH SupplierSales AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, 
        s.s_name
),
CustomerSummary AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, 
        c.c_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SupplierSales s
)
SELECT 
    cs.c_name,
    cs.order_count,
    cs.avg_order_value,
    COALESCE(ts.s_name, 'No Supplier') AS top_supplier
FROM 
    CustomerSummary cs
LEFT JOIN 
    TopSuppliers ts ON cs.order_count > 0 AND ts.sales_rank = 1
WHERE 
    cs.avg_order_value IS NOT NULL 
    AND cs.c_custkey IN (
        SELECT DISTINCT 
            o.o_custkey 
        FROM 
            orders o 
        WHERE 
            o.o_orderstatus = 'F'
    )
    AND (cs.order_count > 1 OR cs.avg_order_value > 500)
ORDER BY 
    cs.avg_order_value DESC;
