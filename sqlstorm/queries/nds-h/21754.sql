WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost DESC) AS rnk
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
), 
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           SUM(l.l_quantity * l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY o.o_orderkey) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('O', 'F') AND o.o_totalprice > 1000
), 
NationsRanked AS (
    SELECT n.n_nationkey, n.n_name,
           COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           COUNT(DISTINCT l.l_orderkey) AS order_count,
           ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT s.s_suppkey) DESC) AS nation_rank
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY n.n_nationkey, n.n_name
), 
FilteredNations AS (
    SELECT n.n_nationkey, n.n_name
    FROM NationsRanked n
    WHERE n.supplier_count > COALESCE((SELECT AVG(supplier_count) FROM NationsRanked), 0)
)
SELECT DISTINCT r.r_name,
       COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
       COUNT(DISTINCT oi.o_orderkey) AS total_orders,
       ns.n_name AS nation_name
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN FilteredNations ns ON ns.n_nationkey = n.n_nationkey
LEFT JOIN HighValueOrders oi ON oi.o_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
)
LEFT JOIN lineitem l ON oi.o_orderkey = l.l_orderkey
WHERE r.r_name IS NOT NULL AND ns.n_name IS NOT NULL
GROUP BY r.r_name, ns.n_name
HAVING SUM(l.l_extendedprice) IS NOT NULL
ORDER BY total_revenue DESC, r.r_name ASC;