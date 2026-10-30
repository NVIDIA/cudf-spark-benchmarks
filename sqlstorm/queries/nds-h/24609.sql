WITH  RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
), 
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, c.c_nationkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_income,
           RANK() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= DATE '1997-01-01' 
      AND o.o_orderstatus IN ('O', 'P') 
    GROUP BY o.o_orderkey, o.o_totalprice, c.c_nationkey
), 
SupplierPerformance AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost, 
           count(DISTINCT o.o_orderkey) AS order_count
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey
)
SELECT rs.s_name, 
       n.n_name AS nation_name, 
       COUNT(DISTINCT h.o_orderkey) AS HighValueOrdersCount, 
       MAX(sp.total_supplycost) AS MaxSupplyCost,
       SUM(CASE WHEN h.total_income IS NULL THEN 0 ELSE h.total_income END) AS TotalIncome
FROM RankedSuppliers rs
JOIN nation n ON rs.s_nationkey = n.n_nationkey
LEFT JOIN HighValueOrders h ON rs.s_suppkey = h.c_nationkey 
LEFT JOIN SupplierPerformance sp ON rs.s_suppkey = sp.ps_suppkey
WHERE rs.rank <= 5
GROUP BY rs.s_name, n.n_name
HAVING SUM(sp.total_supplycost) IS NOT NULL OR COUNT(h.o_orderkey) > 0
ORDER BY MaxSupplyCost DESC, HighValueOrdersCount DESC;