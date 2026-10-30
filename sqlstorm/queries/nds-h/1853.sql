WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.total_sales
    FROM 
        SupplierSales ss
    WHERE 
        ss.sales_rank <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    COALESCE(t.s_name, 'Unknown Supplier') AS SupplierName,
    COALESCE(c.c_name, 'No Orders') AS CustomerName,
    COALESCE(c.order_count, 0) AS OrderCount,
    COALESCE(c.total_spent, 0) AS TotalSpent,
    CASE 
        WHEN c.total_spent > 10000 THEN 'Premium'
        ELSE 'Standard'
    END AS CustomerCategory
FROM 
    TopSuppliers t
FULL OUTER JOIN 
    CustomerOrders c ON t.s_suppkey = c.c_custkey
WHERE 
    (t.total_sales IS NOT NULL OR c.order_count IS NOT NULL)
ORDER BY 
    t.total_sales DESC NULLS LAST, 
    c.total_spent DESC NULLS LAST;
