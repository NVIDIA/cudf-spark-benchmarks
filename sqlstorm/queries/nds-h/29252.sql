WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        p.p_name,
        ROW_NUMBER() OVER (PARTITION BY p.p_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrderStats AS (
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
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        cs.total_spent,
        ROW_NUMBER() OVER (ORDER BY cs.total_spent DESC) AS customer_rank
    FROM 
        CustomerOrderStats cs
    JOIN 
        customer c ON cs.c_custkey = c.c_custkey
    WHERE 
        cs.order_count > 5
)
SELECT 
    ts.c_name AS Top_Customer_Name,
    ts.total_spent AS Total_Spent,
    rs.p_name AS Part_Name,
    rs.s_name AS Supplier_Name,
    rs.s_acctbal AS Supplier_Account_Balance
FROM 
    TopCustomers ts
JOIN 
    RankedSuppliers rs ON ts.c_custkey = rs.s_suppkey
WHERE 
    rs.rank = 1
ORDER BY 
    ts.total_spent DESC, rs.s_acctbal DESC;
