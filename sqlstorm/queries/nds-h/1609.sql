
WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_sales
    FROM 
        supplier s
    JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    WHERE 
        ss.sales_rank <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierCustomers AS (
    SELECT 
        ts.s_suppkey,
        ts.s_name,
        COUNT(DISTINCT co.c_custkey) AS unique_customers
    FROM 
        TopSuppliers ts
    JOIN 
        lineitem l ON ts.s_suppkey = l.l_suppkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer co ON o.o_custkey = co.c_custkey
    GROUP BY 
        ts.s_suppkey, ts.s_name
)
SELECT 
    sc.s_suppkey,
    sc.s_name,
    sc.unique_customers,
    cs.c_custkey,
    cs.c_name,
    cs.order_count,
    cs.total_spent
FROM 
    SupplierCustomers sc
LEFT JOIN 
    CustomerOrders cs ON sc.unique_customers > 0
WHERE 
    cs.total_spent IS NOT NULL 
ORDER BY 
    sc.s_suppkey, cs.total_spent DESC
LIMIT 10;
