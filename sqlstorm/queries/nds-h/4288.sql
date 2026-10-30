WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate, 
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
),
SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        COUNT(DISTINCT p.p_partkey) AS supplied_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS order_count, 
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    r.r_name AS region_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    cs.total_spent AS customer_spending,
    ss.avg_supplycost AS average_supplier_costs,
    COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied,
    MAX(o.o_orderdate) AS last_order_date
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN RankedOrders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN CustomerOrders cs ON o.o_orderkey = cs.c_custkey
LEFT JOIN SupplierStats ss ON s.s_suppkey = ss.s_suppkey
WHERE r.r_name IS NOT NULL 
AND (cs.order_count > 5 OR ss.total_available > 10)
GROUP BY r.r_name, cs.total_spent, ss.avg_supplycost
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY revenue DESC, region_name;
