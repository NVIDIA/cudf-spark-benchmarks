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
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ss.total_sales
    FROM 
        supplier s
    JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    WHERE 
        s.s_acctbal > 1000
    ORDER BY 
        ss.total_sales DESC
    LIMIT 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    ts.s_name AS Supplier_Name, 
    ts.total_sales AS Supplier_Total_Sales, 
    co.c_name AS Customer_Name, 
    co.total_orders AS Customer_Total_Orders
FROM 
    TopSuppliers ts
JOIN 
    CustomerOrders co ON ts.s_suppkey = co.c_custkey
WHERE 
    ts.total_sales > 5000
ORDER BY 
    ts.total_sales DESC, co.total_orders DESC;
