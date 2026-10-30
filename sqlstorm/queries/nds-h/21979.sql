WITH  ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER(PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F')
), supplier_availability AS (
    SELECT 
        p.p_partkey,
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE p.p_size > 10
    GROUP BY p.p_partkey, s.s_suppkey
), customer_order_summary AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
), null_handling AS (
    SELECT 
        c.c_custkey,
        COALESCE(cos.order_count, 0) AS orders,
        COALESCE(cos.total_spent, 0) AS spend
    FROM customer c
    LEFT JOIN customer_order_summary cos ON c.c_custkey = cos.c_custkey
), bizarre_supplier_shipping AS (
    SELECT 
        s.s_name,
        s.s_acctbal * (1 + (CASE WHEN s.s_acctbal IS NOT NULL THEN 0.1 ELSE 0 END)) AS adjusted_balance,
        COUNT(DISTINCT l.l_orderkey) AS orders_shipped
    FROM supplier s
    LEFT JOIN lineitem l ON s.s_suppkey = l.l_suppkey
    WHERE l.l_shipdate IS NOT NULL OR l.l_commitdate IS NOT NULL
    GROUP BY s.s_name, adjusted_balance
)
SELECT 
    rs.o_orderkey,
    rs.o_orderstatus,
    rs.o_totalprice,
    na.orders,
    na.spend,
    bss.s_name,
    bss.adjusted_balance,
    bss.orders_shipped
FROM ranked_orders rs
JOIN null_handling na ON NA.orders > 0
LEFT JOIN bizarre_supplier_shipping bss ON bss.orders_shipped > (SELECT COUNT(*) FROM lineitem) / 2
WHERE rs.order_rank <= 5
ORDER BY rs.o_totalprice DESC, na.spend DESC
LIMIT 100;
