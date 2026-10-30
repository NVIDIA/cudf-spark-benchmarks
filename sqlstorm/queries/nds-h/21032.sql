WITH RankedOrders AS (
    SELECT o.o_orderkey, 
           o.o_orderdate, 
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM orders o
    WHERE o.o_orderdate > (cast('1998-10-01' as date) - INTERVAL '1 year')
),
FilteredSuppliers AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           SUM(ps.ps_availqty) AS total_available
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 0
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_availqty) > (SELECT AVG(ps_availqty) FROM partsupp)
),
CustomerStatistics AS (
    SELECT c.c_nationkey,
           COUNT(DISTINCT c.c_custkey) AS total_customers,
           AVG(c.c_acctbal) AS avg_balance
    FROM customer c
    GROUP BY c.c_nationkey
)
SELECT p.p_partkey,
       p.p_name,
       COALESCE(fs.total_available, 0) AS available_suppliers,
       cs.total_customers,
       cs.avg_balance,
       CASE
           WHEN p.p_size IS NULL THEN 'Unknown Size'
           ELSE CONCAT('Size: ', p.p_size)
       END AS size_info
FROM part p
LEFT JOIN FilteredSuppliers fs ON p.p_partkey = fs.s_suppkey
INNER JOIN CustomerStatistics cs ON p.p_partkey % 10 = cs.c_nationkey
WHERE EXISTS (
    SELECT 1 
    FROM lineitem l
    WHERE l.l_partkey = p.p_partkey 
      AND l.l_shipdate <= cast('1998-10-01' as date)
      AND l.l_returnflag = 'N'
)
AND p.p_retailprice BETWEEN (SELECT AVG(p_retailprice) FROM part) * 0.9 AND (SELECT AVG(p_retailprice) FROM part) * 1.1
ORDER BY cs.avg_balance DESC, available_suppliers DESC
LIMIT 100;