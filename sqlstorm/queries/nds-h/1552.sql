WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice,
           RANK() OVER (ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate >= DATE '1997-01-01'
),
CustomerOrderSummary AS (
    SELECT c.c_custkey, c.c_name, COALESCE(SUM(lo.l_extendedprice * (1 - lo.l_discount)), 0) AS total_spent,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem lo ON o.o_orderkey = lo.l_orderkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT cs.c_custkey, cs.c_name, cs.total_spent, cs.order_count, hs.s_name, hs.s_acctbal,
       p.p_name, p.p_retailprice
FROM CustomerOrderSummary cs
JOIN HighValueOrders ho ON cs.order_count > 5 AND ho.o_custkey = cs.c_custkey
LEFT JOIN RankedSuppliers hs ON hs.rn = 1 AND hs.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_size > 5 AND p.p_retailprice < 100
)
JOIN lineitem l ON ho.o_orderkey = l.l_orderkey
JOIN part p ON l.l_partkey = p.p_partkey
WHERE cs.total_spent > 5000.00
  AND l.l_returnflag = 'N'
ORDER BY cs.total_spent DESC, hs.s_acctbal ASC
LIMIT 10;