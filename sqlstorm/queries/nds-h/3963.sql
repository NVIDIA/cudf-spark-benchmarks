WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) as ranking
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) as rn
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 10000
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '1 year'
    GROUP BY o.o_orderkey, o.o_orderdate
),
SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT l.l_orderkey) AS order_count,
        SUM(l.l_extendedprice) AS total_sales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(COALESCE(l.l_extendedprice * (1 - l.l_discount), 0)) AS total_sales,
    AVG(s.s_acctbal) AS avg_supplier_acctbal,
    COUNT(DISTINCT h.c_custkey) AS high_value_customers,
    COUNT(DISTINCT r_sup.s_suppkey) AS ranked_suppliers
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN HighValueCustomers h ON o.o_custkey = h.c_custkey
LEFT JOIN RankedSuppliers r_sup ON s.s_suppkey = r_sup.s_suppkey AND r_sup.ranking = 1
WHERE o.o_orderstatus = 'F'
GROUP BY r.r_name
HAVING COUNT(DISTINCT o.o_orderkey) > 10 AND AVG(s.s_acctbal) > 5000
ORDER BY total_sales DESC;