
WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
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
CustomerOrderStats AS (
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
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rank,
        total_sales
    FROM 
        SupplierSales s
    WHERE 
        total_sales > 10000
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        ROW_NUMBER() OVER (ORDER BY total_spent DESC) AS rank,
        total_spent
    FROM 
        CustomerOrderStats c
    WHERE 
        total_spent > 5000
)
SELECT 
    ts.s_name AS supplier_name,
    tc.c_name AS customer_name,
    ts.total_sales,
    tc.total_spent
FROM 
    TopSuppliers ts
FULL OUTER JOIN 
    TopCustomers tc ON ts.rank = tc.rank
WHERE 
    COALESCE(ts.total_sales, 0) + COALESCE(tc.total_spent, 0) > 6000
ORDER BY 
    ts.s_name, tc.c_name;
