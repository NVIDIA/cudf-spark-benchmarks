
WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS num_orders,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND 
        o.o_orderdate < '1998-01-01' 
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        ss.s_suppkey, ss.s_name, ss.total_sales, ss.num_orders
    FROM 
        SupplierSales ss
    WHERE 
        ss.sales_rank <= 10
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        c.c_acctbal
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, c.c_name, c.total_orders, c.total_spent, c.c_acctbal
    FROM 
        CustomerOrders c
    WHERE 
        c.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
)
SELECT 
    h.c_name AS CustomerName,
    h.total_orders AS OrdersCount,
    h.total_spent AS TotalSpent,
    COALESCE(s.total_sales, 0) AS SupplierSales
FROM 
    HighValueCustomers h
LEFT JOIN 
    TopSuppliers s ON h.c_custkey = s.s_suppkey
ORDER BY 
    h.total_spent DESC
LIMIT 50;
