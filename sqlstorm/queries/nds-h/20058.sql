WITH  customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'F') AND o.o_orderdate >= '1996-01-01'
),
supplier_part_counts AS (
    SELECT s.s_suppkey, COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
featured_suppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           CASE WHEN s.s_acctbal IS NULL THEN 'Unknown Balance'
                WHEN s.s_acctbal < 1000 THEN 'Low Balance'
                ELSE 'Sufficient Balance' END AS balance_status
    FROM supplier s
    WHERE s.s_name LIKE '%Inc%'
)
SELECT co.c_custkey, co.c_name, co.o_orderkey, co.o_orderdate, co.o_totalprice,
       spc.s_suppkey, spc.part_count, fs.balance_status
FROM customer_orders co
FULL OUTER JOIN supplier_part_counts spc ON co.o_orderkey = spc.s_suppkey
LEFT JOIN featured_suppliers fs ON spc.s_suppkey = fs.s_suppkey
WHERE (co.o_totalprice > (SELECT AVG(o_totalprice) FROM orders WHERE o_orderdate < '1997-01-01')
       OR fs.balance_status = 'Low Balance')
  AND (fs.s_acctbal IS NOT NULL OR fs.s_suppkey IS NULL)
ORDER BY co.o_orderdate DESC, fs.balance_status, spc.part_count DESC
LIMIT 100;