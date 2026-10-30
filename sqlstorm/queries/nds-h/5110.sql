WITH TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_supply_cost DESC
    LIMIT 5
),
CustomerSpending AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '1997-01-01'
    GROUP BY c.c_custkey, c.c_name
),
ProductPopularity AS (
    SELECT p.p_partkey, p.p_name, COUNT(l.l_orderkey) AS order_count
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate >= '1997-01-01'
    GROUP BY p.p_partkey, p.p_name
    ORDER BY order_count DESC
    LIMIT 10
)
SELECT ts.s_suppkey, ts.s_name, cs.c_custkey, cs.c_name, cs.total_spent, pp.p_partkey, pp.p_name, pp.order_count
FROM TopSuppliers ts
CROSS JOIN CustomerSpending cs
JOIN ProductPopularity pp ON pp.order_count > 0
WHERE pp.p_partkey IN (
    SELECT ps.ps_partkey
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_nationkey IN (
        SELECT n.n_nationkey
        FROM nation n
        WHERE n.n_regionkey = (
            SELECT r.r_regionkey
            FROM region r
            WHERE r.r_name = 'ASIA'
        )
    )
)
ORDER BY ts.total_supply_cost DESC, cs.total_spent DESC;