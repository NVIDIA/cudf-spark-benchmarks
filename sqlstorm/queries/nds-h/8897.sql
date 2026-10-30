WITH SupplierCost AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sc.total_supply_cost
    FROM 
        supplier s
    JOIN 
        SupplierCost sc ON s.s_suppkey = sc.s_suppkey
    ORDER BY 
        total_supply_cost DESC
    LIMIT 10
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
HighSpenders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        co.total_spent
    FROM 
        customerOrders co
    JOIN 
        customer c ON co.c_custkey = c.c_custkey
    WHERE 
        total_spent > (SELECT AVG(total_spent) FROM customerOrders)
)
SELECT 
    ts.s_name,
    hs.c_name,
    hs.total_spent,
    ts.total_supply_cost
FROM 
    TopSuppliers ts
JOIN 
    HighSpenders hs ON ts.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O')) LIMIT 1)
ORDER BY 
    ts.total_supply_cost DESC, hs.total_spent DESC;
