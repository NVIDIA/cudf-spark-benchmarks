
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
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
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    GROUP BY 
        c.c_custkey, c.c_name
), 

HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        CASE
            WHEN c.c_acctbal IS NULL THEN 'No Balance'
            WHEN c.c_acctbal >= 10000 THEN 'High Roller'
            ELSE 'Regular'
        END AS customer_type
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL
)

SELECT 
    hvc.c_name,
    r.s_name AS top_supplier,
    r.s_acctbal,
    cus.total_spent,
    cus.total_orders,
    hvc.customer_type
FROM 
    HighValueCustomers hvc
JOIN 
    CustomerOrderStats cus ON hvc.c_custkey = cus.c_custkey
LEFT JOIN 
    RankedSuppliers r ON hvc.c_custkey = r.s_suppkey AND r.rank = 1
WHERE 
    hvc.customer_type = 'High Roller'
ORDER BY 
    cus.total_spent DESC, 
    r.s_acctbal DESC
LIMIT 50;
