WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(s.s_acctbal) AS avg_acct_balance
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_orderkey) AS line_item_count,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
),
CustomerMetrics AS (
    SELECT 
        c.c_custkey,
        SUM(o.total_order_value) AS customer_total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN OrderDetails o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 1000
    GROUP BY c.c_custkey
)

SELECT 
    ns.n_name AS nation,
    rs.r_name AS region,
    SUM(ss.total_parts) AS total_parts_supplied,
    COALESCE(SUM(cm.customer_total_spent), 0) AS total_customer_spent,
    COUNT(DISTINCT ss.s_suppkey) AS total_suppliers,
    AVG(ss.avg_acct_balance) AS avg_supplier_balance
FROM nation ns
JOIN region rs ON ns.n_regionkey = rs.r_regionkey
LEFT JOIN SupplierSummary ss ON ns.n_nationkey = ss.s_suppkey
LEFT JOIN CustomerMetrics cm ON ns.n_nationkey = cm.c_custkey
GROUP BY ns.n_name, rs.r_name
HAVING COUNT(DISTINCT ss.s_suppkey) > 5 AND SUM(cm.customer_total_spent) > 10000
ORDER BY total_customer_spent DESC, total_parts_supplied ASC;
