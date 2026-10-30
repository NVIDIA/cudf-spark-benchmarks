WITH  supplier_partition AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ps.ps_supplycost, ps.ps_availqty,
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) as rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL
),
customer_totals AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
region_summary AS (
    SELECT r.r_name, COUNT(n.n_nationkey) AS nation_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_name
)
SELECT 
    sp.s_name,
    sp.s_acctbal,
    CASE 
        WHEN sp.ps_availqty IS NULL THEN 'No Availability' 
        ELSE CAST(sp.ps_availqty AS STRING) 
    END AS avail_qty_status,
    ct.total_spent,
    rs.r_name,
    rs.nation_count
FROM supplier_partition sp
FULL OUTER JOIN customer_totals ct ON sp.s_suppkey = ct.c_custkey
JOIN region_summary rs ON (
    CASE 
        WHEN rs.nation_count > 5 THEN rs.r_name LIKE 'A%' 
        ELSE rs.r_name LIKE 'B%' 
    END
) 
WHERE sp.rn <= 3
ORDER BY sp.s_name, ct.total_spent DESC, rs.nation_count DESC;
