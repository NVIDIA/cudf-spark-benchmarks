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
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_sales
    FROM 
        SupplierSales ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    ORDER BY 
        ss.total_sales DESC
    LIMIT 5
),
CustOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT 
        cu.c_custkey,
        cu.c_name,
        cu.order_count,
        cu.total_spent
    FROM 
        CustOrders cu
    WHERE 
        cu.total_spent > (SELECT AVG(total_spent) FROM CustOrders)
)
SELECT 
    ts.s_name AS Supplier_Name,
    hvc.c_name AS Customer_Name,
    hvc.total_spent AS Customer_Spending,
    ts.total_sales AS Supplier_Total_Sales
FROM 
    TopSuppliers ts
CROSS JOIN 
    HighValueCustomers hvc
ORDER BY 
    ts.total_sales DESC, hvc.total_spent DESC;
