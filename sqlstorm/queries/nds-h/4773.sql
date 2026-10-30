
WITH SupplierRank AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        CASE 
            WHEN c.c_acctbal IS NOT NULL AND c.c_acctbal > 1000 THEN 'High'
            ELSE 'Low'
        END AS customer_value
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        COUNT(DISTINCT l.l_linenumber) AS item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
TotalOrderValue AS (
    SELECT 
        AVG(total_value) AS avg_order_value,
        COUNT(DISTINCT o_orderkey) AS total_orders
    FROM OrderDetails
),
NationStats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(s.s_suppkey) AS supplier_count,
        SUM(COALESCE(s.s_acctbal, 0)) AS total_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    ns.n_name,
    ns.supplier_count,
    ns.total_acctbal,
    COALESCE(cvc.customer_value, 'Unknown') AS customer_value_category,
    od.total_value,
    od.item_count,
    tr.avg_order_value,
    tr.total_orders
FROM NationStats ns
LEFT JOIN HighValueCustomers cvc ON ns.supplier_count > 5
JOIN OrderDetails od ON ns.supplier_count < 3
CROSS JOIN TotalOrderValue tr
WHERE ns.total_acctbal > 5000
ORDER BY ns.total_acctbal DESC, od.total_value DESC;
