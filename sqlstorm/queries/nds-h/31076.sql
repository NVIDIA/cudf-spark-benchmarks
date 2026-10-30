WITH  OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, 
           ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY o_orderdate) AS order_seq
    FROM orders
    WHERE o_orderdate >= '1997-01-01'
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '1997-01-01'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice BETWEEN 50 AND 200
),
NationSummary AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS count_suppliers
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
CustomerOrderDetails AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           AVG(o.o_totalprice) AS avg_order_value, d.count_suppliers
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN NationSummary d ON c.c_nationkey = d.n_nationkey
    GROUP BY c.c_custkey, c.c_name, d.count_suppliers
)
SELECT 
    co.c_name,
    co.order_count,
    COALESCE(NTH_VALUE(co.avg_order_value, 2) OVER (PARTITION BY co.count_suppliers ORDER BY co.order_count DESC), 0) AS second_highest_order_value,
    ps.p_name,
    ps.ps_supplycost,
    oh.o_orderdate,
    ROW_NUMBER() OVER (ORDER BY co.order_count DESC) as customer_rank
FROM CustomerOrderDetails co
JOIN SupplierParts ps ON co.order_count > 5
LEFT JOIN OrderHierarchy oh ON co.c_custkey = oh.o_custkey
WHERE oh.order_seq < 4
ORDER BY co.order_count DESC, co.c_name ASC
LIMIT 50;