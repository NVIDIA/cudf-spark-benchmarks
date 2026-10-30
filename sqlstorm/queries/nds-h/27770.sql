WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_phone,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
PopularParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(l.l_partkey) AS total_orders
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        COUNT(l.l_partkey) > 50
)
SELECT 
    rs.s_name AS Supplier_Name,
    rs.s_phone AS Supplier_Phone,
    co.total_spent AS Customer_Total_Spent,
    pp.p_name AS Popular_Part_Name,
    pp.total_orders AS Part_Order_Count
FROM 
    RankedSuppliers rs
JOIN 
    CustomerOrders co ON co.c_custkey = (SELECT c.c_custkey FROM customer c LIMIT 1)
CROSS JOIN 
    PopularParts pp
WHERE 
    rs.rn = 1
ORDER BY 
    co.total_spent DESC, pp.total_orders DESC
LIMIT 10;
