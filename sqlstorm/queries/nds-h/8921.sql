WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_cost,
        ss.part_count
    FROM 
        SupplierStats ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    WHERE 
        ss.total_cost > (SELECT AVG(total_cost) FROM SupplierStats)
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > (SELECT AVG(total_spent) FROM (SELECT SUM(o.o_totalprice) AS total_spent FROM orders o GROUP BY o.o_custkey) AS customer_totals)
)
SELECT 
    hs.s_suppkey,
    hs.s_name,
    tc.c_custkey,
    tc.c_name,
    tc.total_spent,
    hs.total_cost
FROM 
    HighValueSuppliers hs
JOIN 
    TopCustomers tc ON hs.part_count > 5
ORDER BY 
    hs.total_cost DESC, tc.total_spent DESC
LIMIT 10;
