
WITH supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS num_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
top_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spending
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '6 MONTH'
    GROUP BY c.c_custkey, c.c_name
    ORDER BY total_spending DESC
    LIMIT 10
),
national_parts AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    ts.c_name AS top_customer,
    ts.total_spending,
    ss.s_name AS supplier_name,
    ss.total_supply_cost,
    np.n_name AS nation,
    np.part_count
FROM top_customers ts
JOIN supplier_summary ss ON ss.num_parts > 5
JOIN national_parts np ON np.part_count < 50
WHERE ts.total_spending > 1000
ORDER BY ts.total_spending DESC, ss.total_supply_cost ASC
LIMIT 10 OFFSET 0;
