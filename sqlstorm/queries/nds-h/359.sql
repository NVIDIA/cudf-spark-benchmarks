
WITH NationSummary AS (
    SELECT n.n_name, SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    INNER JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
),
PartSupplier AS (
    SELECT ps.ps_partkey, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
OrderLineSummary AS (
    SELECT o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_linenumber) AS lineitem_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '1997-01-01' 
      AND l.l_shipdate < '1998-01-01'
    GROUP BY o.o_orderkey
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    ORDER BY total_spent DESC
    LIMIT 10
)
SELECT p.p_name,
       p.p_retailprice,
       ps.avg_supplycost,
       CASE 
           WHEN ts.total_spent IS NULL THEN 'No Orders'
           ELSE CONCAT('Total Spent: $', ts.total_spent)
       END AS order_summary,
       ROW_NUMBER() OVER (PARTITION BY n_summary.n_name ORDER BY p.p_retailprice) AS region_rank
FROM part p
LEFT JOIN PartSupplier ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN NationSummary n_summary ON n_summary.n_name = p.p_mfgr
LEFT JOIN TopCustomers ts ON p.p_partkey = ts.c_custkey
WHERE p.p_retailprice > COALESCE(ps.avg_supplycost, 0) * 1.1
    AND (p.p_comment IS NULL OR p.p_comment LIKE '%special%')
ORDER BY region_rank, p.p_retailprice DESC;
