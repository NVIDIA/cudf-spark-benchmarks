WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name,
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
HighValueParts AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
CustomerOrders AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
)
SELECT r.nation_name, COUNT(DISTINCT c.c_custkey) AS customer_count,
       COUNT(DISTINCT o.o_orderkey) AS order_count,
       SUM(p.total_value) AS total_part_value
FROM RankedSuppliers r
JOIN customer c ON r.s_suppkey = c.c_nationkey
JOIN CustomerOrders o ON c.c_custkey = o.o_custkey
JOIN HighValueParts p ON p.p_partkey = o.o_orderkey
GROUP BY r.nation_name
ORDER BY total_part_value DESC;
