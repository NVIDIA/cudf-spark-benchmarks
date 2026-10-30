WITH  OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_nationkey, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= (cast('1998-10-01' as date) - INTERVAL '1 year')
),
SupplierMetrics AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available, 
           COUNT(s.s_suppkey) AS supplier_count, 
           AVG(s.s_acctbal) AS average_balance
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey
),
RankedLineItems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rev_rank
    FROM lineitem l
    GROUP BY l.l_orderkey
),
NationSummary AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           SUM(l.l_quantity) AS total_quantity
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    oh.o_orderkey, oh.o_orderdate, oh.o_totalprice, 
    nm.n_name, nm.supplier_count, nm.total_quantity,
    sm.total_available, sm.supplier_count AS supplier_count_metrics, 
    sm.average_balance,
    COALESCE(rl.total_revenue, 0) AS total_revenue,
    rl.rev_rank
FROM OrderHierarchy oh
JOIN NationSummary nm ON oh.c_nationkey = nm.n_nationkey
LEFT JOIN SupplierMetrics sm ON nm.supplier_count = sm.supplier_count
LEFT JOIN RankedLineItems rl ON oh.o_orderkey = rl.l_orderkey
WHERE oh.rn = 1
ORDER BY oh.o_totalprice DESC, nm.total_quantity ASC
LIMIT 50;