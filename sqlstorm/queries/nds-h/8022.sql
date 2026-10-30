WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name, 
           ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
PartSupply AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost, 
           p.p_name, p.p_brand, p.p_type, p.p_size, ps.ps_comment, rs.nation_name
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey
    WHERE rs.rn <= 5
),
OrderSummary AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31'
    GROUP BY o.o_custkey
)
SELECT o.c_custkey, o.c_name, o.c_acctbal, ps.p_name, ps.nation_name, os.total_revenue
FROM customer o
JOIN OrderSummary os ON o.c_custkey = os.o_custkey
JOIN PartSupply ps ON ps.ps_partkey IN (
    SELECT p.p_partkey
    FROM part p
    WHERE p.p_brand = 'Brand#25' AND p.p_size > 15
)
WHERE os.total_revenue > 1000000
ORDER BY os.total_revenue DESC, o.c_acctbal DESC
LIMIT 10;