WITH  RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
),
FilteredSuppliers AS (
    SELECT *
    FROM RankedSuppliers
    WHERE rank <= 5
),
OrderStats AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total, COUNT(l.l_linenumber) AS line_item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
MainQuery AS (
    SELECT p.p_partkey, p.p_name, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, AVG(l.l_quantity) AS avg_quantity, MAX(o.order_total) AS max_order_total
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN FilteredSuppliers fs ON ps.ps_suppkey = fs.s_suppkey
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN OrderStats o ON l.l_orderkey = o.o_orderkey
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) 
      AND p.p_size BETWEEN 1 AND 10
      AND fs.s_acctbal IS NOT NULL
    GROUP BY p.p_partkey, p.p_name
)
SELECT m.p_partkey, m.p_name, m.supplier_count, m.avg_quantity, COALESCE(m.max_order_total, 0) AS max_order_total
FROM MainQuery m
WHERE EXISTS (
    SELECT 1
    FROM nation n
    WHERE n.n_nationkey IN (SELECT c.c_nationkey FROM customer c WHERE c.c_acctbal >= 1000)
      AND m.supplier_count > (SELECT COUNT(*) FROM supplier WHERE s_acctbal < 1000)
)
ORDER BY m.supplier_count DESC NULLS LAST
LIMIT 10;
