WITH supplier_info AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
top_suppliers AS (
    SELECT si.*, ROW_NUMBER() OVER (ORDER BY si.s_acctbal DESC) AS rn
    FROM supplier_info si
    WHERE si.part_count > 5
),
order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'R' OR l.l_discount > 0.05
    GROUP BY o.o_orderkey
)
SELECT 
    p.p_name, 
    r.r_name, 
    coalesce(top_sup.s_name, 'Unknown Supplier') AS supplier_name,
    os.total_revenue,
    CASE 
        WHEN os.total_revenue IS NULL THEN 'No Revenue'
        WHEN os.total_revenue > 10000 THEN 'High Revenue'
        ELSE 'Standard Revenue'
    END AS revenue_category
FROM part p 
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN top_suppliers top_sup ON s.s_suppkey = top_sup.s_suppkey
LEFT JOIN order_summary os ON os.total_revenue = (
    SELECT MAX(os2.total_revenue) FROM order_summary os2 
    WHERE os2.o_orderkey % 2 = 0
)
WHERE r.r_name IS NOT NULL 
    AND p.p_retailprice BETWEEN 100 AND 1000 
    AND (s.s_acctbal IS NULL OR p.p_mfgr LIKE 'Manufacturer%' OR top_sup.part_count IS NOT NULL)
ORDER BY revenue_category, p.p_name;
