WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
TopSuppliers AS (
    SELECT 
        *, 
        ROW_NUMBER() OVER (ORDER BY part_count DESC, s_acctbal DESC) AS rn 
    FROM 
        RankedSuppliers
),
CustomerOrders AS (
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
),
TopCustomers AS (
    SELECT 
        *, 
        ROW_NUMBER() OVER (ORDER BY total_spent DESC) AS rn
    FROM 
        CustomerOrders
),
FinalResult AS (
    SELECT 
        tc.c_name AS customer_name,
        ts.s_name AS supplier_name,
        ts.part_count,
        tc.total_spent
    FROM 
        TopCustomers tc
    JOIN 
        TopSuppliers ts ON ts.rn <= 10
)
SELECT 
    customer_name, 
    supplier_name, 
    part_count, 
    total_spent
FROM 
    FinalResult
ORDER BY 
    total_spent DESC, part_count DESC;
