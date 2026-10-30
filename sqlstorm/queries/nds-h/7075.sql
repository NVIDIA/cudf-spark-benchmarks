WITH supplier_summary AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost, 
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
order_summary AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F' 
    GROUP BY o.o_orderkey, o.o_custkey
)
SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    SUM(os.total_order_value) AS total_sales,
    AVG(ss.total_supplycost) AS avg_supplycost,
    SUM(ss.part_count) AS total_parts
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN customer c ON n.n_nationkey = c.c_nationkey
JOIN order_summary os ON c.c_custkey = os.o_custkey
JOIN supplier_summary ss ON ss.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_type LIKE 'metal%')
GROUP BY n.n_name, r.r_name
ORDER BY total_sales DESC, avg_supplycost ASC
LIMIT 10;
