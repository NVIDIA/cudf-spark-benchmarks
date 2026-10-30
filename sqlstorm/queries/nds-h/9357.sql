WITH SupplierAggregates AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
OrderStats AS (
    SELECT o.o_custkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_order_value
    FROM orders o
    GROUP BY o.o_custkey
),
CustomerDetails AS (
    SELECT c.c_custkey, c.c_name, n.n_name AS nation_name, c.c_acctbal
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE c.c_acctbal > 1000
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, sa.total_supply_value
    FROM supplier s
    JOIN SupplierAggregates sa ON s.s_suppkey = sa.s_suppkey
    WHERE sa.total_supply_value > (
        SELECT AVG(total_supply_value) FROM SupplierAggregates
    )
)
SELECT cd.c_name, cd.nation_name, cd.c_acctbal, os.order_count, os.total_order_value, ts.s_name, ts.total_supply_value
FROM CustomerDetails cd
JOIN OrderStats os ON cd.c_custkey = os.o_custkey
JOIN TopSuppliers ts ON cd.c_custkey IN (
    SELECT o.o_custkey 
    FROM orders o 
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
    WHERE l.l_quantity > 100
)
ORDER BY cd.c_acctbal DESC, os.total_order_value DESC
LIMIT 10;
