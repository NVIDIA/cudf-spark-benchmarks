WITH  CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate) AS order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           COUNT(DISTINCT ps.ps_partkey) AS part_count, 
           MAX(ps.ps_supplycost) AS max_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT
    r.r_name AS region,
    COUNT(DISTINCT COALESCE(co.o_orderkey, 0)) AS total_orders,
    MAX(ss.part_count) AS max_parts_supplied,
    SUM(ss.total_cost) AS total_supplier_cost,
    AVG(co.o_totalprice) AS avg_order_value,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY co.o_totalprice) AS median_order_value
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierStats ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN CustomerOrders co ON s.s_suppkey = co.o_orderkey
WHERE (ss.total_cost IS NOT NULL OR ss.part_count > 0)
GROUP BY r.r_name
ORDER BY region;
