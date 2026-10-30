WITH  top_suppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
avg_retail_price AS (
    SELECT p.p_partkey, AVG(p.p_retailprice) AS avg_price
    FROM part p
    GROUP BY p.p_partkey
),
high_demand_items AS (
    SELECT ps.ps_partkey, SUM(l.l_quantity) AS total_quantity
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_partkey
    HAVING SUM(l.l_quantity) > 1000
),
nation_stats AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT ns.n_name, ns.supplier_count, ns.total_acctbal,
       ths.s_name AS top_supplier, ths.s_acctbal AS top_supplier_acctbal,
       COALESCE(hdi.total_quantity, 0) AS high_demand_total_quantity,
       COALESCE(ar.avg_price, 0) AS average_retail_price
FROM nation_stats ns
LEFT JOIN top_suppliers ths ON ns.supplier_count > 0 AND ths.rank = 1
LEFT JOIN high_demand_items hdi ON ns.n_nationkey = hdi.ps_partkey
LEFT JOIN avg_retail_price ar ON ar.p_partkey = hdi.ps_partkey
WHERE ns.total_acctbal IS NOT NULL
ORDER BY ns.total_acctbal DESC
LIMIT 10;
