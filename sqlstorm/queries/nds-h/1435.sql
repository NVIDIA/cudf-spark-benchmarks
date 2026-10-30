WITH RankedOrders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_clerk ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
    WHERE o.o_orderstatus = 'O'
      AND o.o_orderdate >= DATE '1996-01-01'
),
SupplierPartDetails AS (
    SELECT s.s_suppkey,
           s.s_name,
           p.p_partkey,
           p.p_name,
           ps.ps_supplycost,
           ps.ps_availqty,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost) AS supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
AggregatedNation AS (
    SELECT n.n_nationkey,
           n.n_name,
           SUM(s.s_acctbal) AS total_balance,
           COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT RANK() OVER (ORDER BY total_balance DESC) AS nation_rank,
       a.n_name,
       a.total_balance,
       ao.o_orderkey,
       ao.o_orderdate,
       ao.o_totalprice,
       spd.s_name AS supplier_name,
       spd.p_name AS part_name,
       spd.ps_supplycost,
       spd.ps_availqty
FROM AggregatedNation a
JOIN RankedOrders ao ON a.customer_count > 0
LEFT JOIN SupplierPartDetails spd ON a.n_nationkey = spd.s_suppkey
WHERE ao.o_orderkey IS NOT NULL
  AND (spd.ps_availqty IS NULL OR spd.ps_availqty < 10)
  AND (spd.ps_supplycost + 0.01 < a.total_balance / NULLIF(a.customer_count, 0))
ORDER BY nation_rank, ao.o_orderdate DESC, spd.ps_supplycost ASC;