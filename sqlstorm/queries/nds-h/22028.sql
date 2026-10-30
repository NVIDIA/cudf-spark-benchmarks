WITH  CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) IS NOT NULL
),
PartSuppliers AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(co.total_spent, 0) AS total_spent
    FROM customer c
    LEFT JOIN CustomerOrders co ON c.c_custkey = co.c_custkey
    WHERE COALESCE(co.total_spent, 0) > (SELECT AVG(total_spent) FROM CustomerOrders)
),
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        MAX(ps.ps_supplycost) AS max_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT 
    hvc.c_custkey,
    hvc.c_name,
    hvc.total_spent,
    p.p_partkey,
    p.p_name,
    COALESCE(spd.total_available, 0) AS total_available,
    COALESCE(spd.max_supplycost, 0) AS max_supplycost
FROM HighValueCustomers hvc
CROSS JOIN PartSuppliers p
LEFT JOIN SupplierPartDetails spd ON p.p_partkey = spd.ps_partkey
WHERE hvc.total_spent > (
        SELECT 
            AVG(total_spent) + AVG(COALESCE(co.total_spent, 0))
        FROM CustomerOrders co 
        WHERE co.rank > 2
    )
ORDER BY hvc.total_spent DESC, p.p_partkey
LIMIT 100;
