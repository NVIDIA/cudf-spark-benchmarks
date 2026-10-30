
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
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SupplierSales s
)
SELECT 
    c.c_name AS customer_name,
    c.total_spent AS total_amount_spent,
    COALESCE(ts.s_name, 'No Supplier') AS top_supplier,
    ts.sales_rank AS supplier_rank
FROM 
    CustomerOrderSummary c
LEFT JOIN 
    TopSuppliers ts ON c.order_count > 5 AND ts.sales_rank = 1
WHERE 
    c.last_order_date >= CURRENT_DATE - INTERVAL '1 year'
ORDER BY 
    c.total_spent DESC
LIMIT 10;
