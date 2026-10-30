WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_custkey
), CustomerSpends AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(ro.total_revenue), 0) AS total_spent,
        COUNT(DISTINCT ro.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN RankedOrders ro ON c.c_custkey = ro.o_orderkey
    GROUP BY c.c_custkey, c.c_name
), SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
), HighValueCustomers AS (
    SELECT 
        cs.c_custkey,
        cs.c_name,
        cs.total_spent
    FROM CustomerSpends cs
    WHERE cs.total_spent > (SELECT AVG(total_spent) FROM CustomerSpends)
), FinalJoin AS (
    SELECT 
        hvc.c_name,
        sp.total_supply_value,
        (CASE WHEN sp.part_count IS NULL THEN 'No Parts' ELSE 'Parts Available' END) AS part_status
    FROM HighValueCustomers hvc
    LEFT JOIN SupplierPartDetails sp ON hvc.c_custkey = sp.s_suppkey
    WHERE hvc.total_spent >= (
        SELECT MAX(total_spent) * 0.1 FROM CustomerSpends
    )
)
SELECT 
    f.c_name,
    COALESCE(f.total_supply_value, 0) AS total_supply_value,
    f.part_status,
    ROW_NUMBER() OVER (ORDER BY f.total_supply_value DESC) AS rank
FROM FinalJoin f
WHERE f.part_status = 'Parts Available'
ORDER BY f.total_supply_value DESC, f.c_name ASC
LIMIT 10;
