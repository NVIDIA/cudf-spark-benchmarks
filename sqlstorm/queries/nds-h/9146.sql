WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey, o.o_totalprice
),
HighValueOrders AS (
    SELECT od.o_orderkey, od.o_custkey
    FROM OrderDetails od
    WHERE od.total_amount > 1000
)
SELECT sd.s_name, sd.nation_name, COUNT(DISTINCT hvo.o_orderkey) AS high_value_order_count
FROM SupplierDetails sd
JOIN partsupp ps ON sd.s_suppkey = ps.ps_suppkey
JOIN lineitem l ON ps.ps_partkey = l.l_partkey
JOIN HighValueOrders hvo ON l.l_orderkey = hvo.o_orderkey
GROUP BY sd.s_name, sd.nation_name
ORDER BY high_value_order_count DESC
LIMIT 10;
