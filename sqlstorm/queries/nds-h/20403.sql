
WITH  supplier_info AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 0
),
high_value_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, 
           (SELECT SUM(ps.ps_availqty) FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey) AS total_availqty 
    FROM part p
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
order_summary AS (
    SELECT o.o_orderkey, o.o_custkey,
           COUNT(l.l_orderkey) AS lineitem_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           AVG(l.l_tax) AS avg_tax_rate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_custkey
),
nation_details AS (
    SELECT n.n_nationkey, n.n_name, r.r_name AS region_name,
           COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
           SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name, r.r_name
)
SELECT 
    pi.p_partkey,
    pi.p_name,
    pi.p_brand,
    pi.p_retailprice,
    COALESCE(si.s_name, 'Unknown Supplier') AS supplier_name,
    nt.n_name AS nation_name,
    nt.supplier_count,
    nt.total_acctbal,
    os.total_sales,
    os.lineitem_count,
    os.avg_tax_rate
FROM high_value_parts pi
LEFT JOIN partsupp ps ON pi.p_partkey = ps.ps_partkey
LEFT JOIN supplier_info si ON si.s_suppkey = ps.ps_suppkey AND si.rnk = 1
JOIN nation_details nt ON si.s_nationkey = nt.n_nationkey
LEFT JOIN order_summary os ON os.o_custkey = nt.n_nationkey
WHERE pi.total_availqty IS NOT NULL
  AND (pi.p_retailprice > 100 OR nt.total_acctbal > 10000)
ORDER BY pi.p_partkey, nt.n_name NULLS LAST, os.total_sales DESC;
