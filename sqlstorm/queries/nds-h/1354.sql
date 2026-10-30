
WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
TopSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank,
        ss.total_sales
    FROM 
        SupplierSales ss
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    ts.s_name,
    ts.total_sales,
    cos.c_name,
    cos.total_orders,
    cos.total_spent
FROM 
    TopSuppliers ts
FULL OUTER JOIN 
    CustomerOrderSummary cos ON ts.s_suppkey = cos.c_custkey
WHERE 
    (ts.total_sales > 50000 OR cos.total_spent > 10000)
    AND (cos.total_orders IS NULL OR ts.total_sales IS NOT NULL)
ORDER BY 
    ts.total_sales DESC, cos.total_spent DESC
LIMIT 50;
