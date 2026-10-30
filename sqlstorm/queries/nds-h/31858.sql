WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
OngoingOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),
SupplierSummary AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS total_supply_cost, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
NationStats AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count, AVG(s.s_acctbal) AS avg_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
CombinedStats AS (
    SELECT nh.n_nationkey, nh.n_name, COALESCE(ns.supplier_count, 0) AS supplier_count, COALESCE(ns.avg_acctbal, 0) AS avg_acctbal
    FROM NationStats ns
    RIGHT JOIN nation nh ON ns.n_nationkey = nh.n_nationkey
)
SELECT p.p_partkey, 
       p.p_name, 
       ps.total_supply_cost, 
       o.total_revenue, 
       c.supplier_count, 
       c.avg_acctbal
FROM part p
LEFT JOIN SupplierSummary ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN OngoingOrders o ON o.o_orderkey = (
        SELECT o1.o_orderkey
        FROM orders o1
        WHERE o1.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA'))
        ORDER BY o1.o_orderdate DESC
        LIMIT 1
) 
LEFT JOIN CombinedStats c ON p.p_partkey = c.n_nationkey
WHERE p.p_retailprice > (
        SELECT AVG(p2.p_retailprice) 
        FROM part p2 
        WHERE p2.p_size < 20
    )
ORDER BY total_revenue DESC NULLS LAST
LIMIT 10;
