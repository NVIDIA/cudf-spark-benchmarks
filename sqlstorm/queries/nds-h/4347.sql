WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_custkey
), CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)

SELECT 
    cs.c_name,
    COALESCE(cs.total_spent, 0) AS total_spent,
    COALESCE(cs.order_count, 0) AS order_count,
    COALESCE(ss.total_available, 0) AS total_available_parts,
    COALESCE(ss.avg_supply_cost, 0) AS avg_supply_cost,
    CASE 
        WHEN cs.total_spent > 10000 THEN 'High Value'
        WHEN cs.total_spent > 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM CustomerSummary cs
LEFT JOIN SupplierStats ss ON ss.s_suppkey = (SELECT ps.ps_suppkey 
                                                FROM partsupp ps 
                                                JOIN part p ON ps.ps_partkey = p.p_partkey 
                                                WHERE p.p_brand = 'Brand#1' ORDER BY ps.ps_supplycost LIMIT 1)
ORDER BY total_spent DESC, cs.c_name;
