
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
),
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    p.p_name,
    COUNT(l.l_orderkey) AS num_line_items,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COALESCE(cos.total_orders, 0) AS total_orders_by_customer,
    COALESCE(cos.avg_order_value, 0) AS avg_order_value_by_customer,
    CASE 
        WHEN (sr.total_available IS NULL OR sr.total_available < 100) THEN 'Low Availability'
        ELSE 'Sufficient Stock'
    END AS stock_status,
    r.r_name AS region_name,
    n.n_name AS nation_name
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN SupplierPartDetails sr ON sr.ps_partkey = p.p_partkey
LEFT JOIN CustomerOrderStats cos ON cos.c_custkey = (
    SELECT c.c_custkey
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderkey = (
        SELECT o2.o_orderkey
        FROM RankedOrders o2
        WHERE o2.order_rank = 1
        LIMIT 1
    )
)
JOIN supplier s ON l.l_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    p.p_name, 
    cos.total_orders, 
    cos.avg_order_value,
    sr.total_available, 
    r.r_name, 
    n.n_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY 
    total_revenue DESC;
