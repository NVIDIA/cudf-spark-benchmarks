WITH  TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, ROW_NUMBER() OVER (ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1997-01-01' AND l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, o.o_custkey
),
CustomerNation AS (
    SELECT c.c_custkey, c.c_name, n.n_name AS nation_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, n.n_name
),
SupplierParts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
RankedResults AS (
    SELECT C.nation_name, COUNT(DISTINCT C.c_custkey) AS customer_count,
           AVG(C.total_spent) AS avg_spent,
           AVG(H.total_order_value) AS avg_order_value
    FROM CustomerNation C
    LEFT JOIN HighValueOrders H ON C.c_custkey = H.o_custkey
    WHERE C.total_spent IS NOT NULL
    GROUP BY C.nation_name
)
SELECT T.s_name, T.s_acctbal, R.nation_name, R.customer_count, R.avg_spent, R.avg_order_value
FROM TopSuppliers T
LEFT JOIN RankedResults R ON T.rn <= 10
ORDER BY T.s_acctbal DESC, R.avg_spent DESC NULLS LAST
LIMIT 10;