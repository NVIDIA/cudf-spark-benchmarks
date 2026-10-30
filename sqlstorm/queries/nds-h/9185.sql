WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        n.n_name AS nation_name, 
        SUM(ps.ps_availqty) AS total_available_qty, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        AVG(s.s_acctbal) AS avg_account_balance
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(DISTINCT l.l_linenumber) AS item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, o.o_orderdate
),
SupplierOrderStats AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        os.total_order_value,
        os.item_count,
        ss.total_available_qty,
        ss.total_supply_value,
        ss.avg_account_balance
    FROM SupplierStats ss
    JOIN lineitem l ON ss.s_suppkey = l.l_suppkey
    JOIN OrderSummary os ON l.l_orderkey = os.o_orderkey
)
SELECT 
    s.s_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(os.total_order_value) AS avg_order_value,
    SUM(os.total_supply_value) AS total_supply_value,
    MAX(os.avg_account_balance) AS max_account_balance
FROM SupplierOrderStats os
JOIN supplier s ON os.s_suppkey = s.s_suppkey
JOIN orders o ON os.total_order_value = o.o_orderkey
GROUP BY s.s_name
ORDER BY total_supply_value DESC, order_count DESC;
