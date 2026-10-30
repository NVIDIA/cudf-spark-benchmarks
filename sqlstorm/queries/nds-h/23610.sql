
WITH  supplier_totals AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
nation_supply AS (
    SELECT n.n_name, SUM(st.total_supply_cost) AS total_nation_supply
    FROM nation n
    LEFT JOIN supplier_totals st ON n.n_nationkey = (SELECT MAX(s.s_nationkey) FROM supplier s WHERE s.s_suppkey IN (SELECT DISTINCT ps.ps_suppkey FROM partsupp ps))
    GROUP BY n.n_name
)
SELECT 
    p.p_name,
    CASE
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) IS NULL THEN 'No Sales'
        ELSE COALESCE(CAST(SUM(l.l_extendedprice * (1 - l.l_discount)) AS STRING), '0')
    END AS total_sales,
    nt.total_nation_supply,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY nt.total_nation_supply DESC) AS rank_by_supply,
    CASE
        WHEN nt.total_nation_supply IS NULL THEN 'N/A'
        ELSE p.p_comment
    END AS part_comment
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN nation_supply nt ON nt.total_nation_supply > 0
WHERE (l.l_shipdate <= DATE '1998-10-01' OR l.l_shipdate IS NULL)
  AND (p.p_retailprice BETWEEN 0 AND 100 OR p.p_retailprice IS NULL)
GROUP BY p.p_name, nt.total_nation_supply, p.p_partkey, p.p_comment
HAVING COUNT(l.l_orderkey) > 5
   OR MAX(nt.total_nation_supply) IS NOT NULL
ORDER BY total_sales DESC, rank_by_supply ASC;
