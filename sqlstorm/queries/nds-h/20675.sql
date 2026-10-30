WITH regional_supplier AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, r.r_name, s.s_acctbal,
           CASE 
               WHEN s.s_acctbal < 0 THEN 'Negative Balance'
               WHEN s.s_acctbal BETWEEN 0 AND 1000 THEN 'Low Balance'
               WHEN s.s_acctbal > 1000 AND s.s_acctbal < 5000 THEN 'Medium Balance'
               ELSE 'High Balance'
           END AS balance_category
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
), 
part_details AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_retailprice, 
           COUNT(ps.ps_suppkey) AS supply_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_mfgr, p.p_retailprice
), 
order_summary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
)
SELECT rs.r_name, rs.s_name, pd.p_name, os.total_amount
FROM regional_supplier rs
FULL OUTER JOIN part_details pd ON rs.s_nationkey = pd.p_partkey
FULL OUTER JOIN order_summary os ON rs.s_suppkey = os.o_custkey
WHERE rs.balance_category <> 'Negative Balance'
    AND (os.total_amount > 10000 OR os.total_amount IS NULL)
    AND COALESCE(pd.supply_count, 0) > 0
ORDER BY rs.r_name DESC NULLS LAST, os.total_amount ASC;
