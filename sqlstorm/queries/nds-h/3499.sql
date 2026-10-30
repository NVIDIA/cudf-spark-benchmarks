
WITH region_summary AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(s.s_acctbal) AS total_supply_balance
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey, r.r_name
),
order_summary AS (
    SELECT 
        c.c_nationkey,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_nationkey
),
combined_summary AS (
    SELECT 
        r.r_name,
        rs.nation_count,
        rs.total_supply_balance,
        os.total_order_value,
        os.total_orders,
        os.avg_order_value
    FROM region_summary rs
    LEFT JOIN region r ON rs.r_regionkey = r.r_regionkey
    LEFT JOIN order_summary os ON rs.r_regionkey = os.c_nationkey
)
SELECT 
    c.c_name,
    COALESCE(cs.total_order_value, 0) AS order_value,
    COALESCE(cs.total_orders, 0) AS orders_count,
    COALESCE(cs.avg_order_value, 0) AS avg_order_amt,
    CASE 
        WHEN COALESCE(cs.total_order_value, 0) > 50000 THEN 'High Value'
        WHEN COALESCE(cs.total_order_value, 0) > 20000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS order_value_category
FROM customer c
FULL OUTER JOIN combined_summary cs ON c.c_nationkey = cs.nation_count
WHERE c.c_acctbal IS NOT NULL
ORDER BY COALESCE(cs.total_order_value, 0) DESC, c.c_name;
