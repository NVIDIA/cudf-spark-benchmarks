WITH SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, COUNT(DISTINCT ps.ps_partkey) AS num_parts
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
MaxOrders AS (
    SELECT o.o_custkey, MAX(o.o_totalprice) AS max_totalprice
    FROM orders o
    GROUP BY o.o_custkey
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '1996-01-01' AND l.l_shipdate < '1997-01-01'
    GROUP BY o.o_orderkey, o.o_custkey
),
FilteredOrders AS (
    SELECT od.o_orderkey, od.o_custkey
    FROM OrderDetails od
    WHERE od.total_revenue > (SELECT AVG(od2.total_revenue) FROM OrderDetails od2)
)
SELECT s.s_suppkey, s.s_name, s.s_acctbal, si.num_parts,
       COALESCE((SELECT COUNT(DISTINCT c.c_custkey) 
                 FROM customer c 
                 WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'FRANCE')), 0) AS french_customers,
       RANK() OVER (PARTITION BY s.s_suppkey ORDER BY s.s_acctbal DESC) AS rank_balance,
       CASE 
           WHEN s.s_acctbal IS NULL THEN 'Balance not available'
           ELSE 'Balance available'
       END AS balance_status
FROM SupplierInfo si
FULL OUTER JOIN supplier s ON si.s_suppkey = s.s_suppkey
WHERE s.s_name LIKE '%Inc%' 
  AND (s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2) 
  OR s.s_acctbal IS NULL) 
  AND (SELECT COUNT(od.o_orderkey) FROM FilteredOrders od WHERE od.o_custkey = s.s_suppkey) > 0
ORDER BY rank_balance DESC, s.s_name;