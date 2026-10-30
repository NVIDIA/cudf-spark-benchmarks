
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        ROW_NUMBER() OVER(PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
),
SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
FilteredSums AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM lineitem l
    JOIN supplier s ON l.l_suppkey = s.s_suppkey
    GROUP BY l.l_partkey
),
CustomerRegions AS (
    SELECT 
        c.c_custkey,
        r.r_regionkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, r.r_regionkey
)

SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    COALESCE(second.total_supply_cost, 0) AS total_supply_cost,
    COALESCE(first.net_revenue, 0) AS net_revenue,
    cr.order_count,
    CASE 
        WHEN cr.order_count IS NULL THEN 'No orders'
        WHEN cr.order_count >= 100 THEN 'High Volume'
        ELSE 'Moderate Volume'
    END AS order_volume_category
FROM part p
LEFT JOIN SupplierCosts second ON p.p_partkey = second.ps_partkey
LEFT JOIN FilteredSums first ON p.p_partkey = first.l_partkey
LEFT JOIN CustomerRegions cr ON cr.c_custkey = (
    SELECT c.c_custkey FROM customer c WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 0
    LIMIT 1
)
WHERE p.p_retailprice BETWEEN 20 AND (
    SELECT AVG(p2.p_retailprice) * 1.1 FROM part p2 WHERE p2.p_size IS NOT NULL
) AND p.p_comment NOT LIKE '%obsolete%'
ORDER BY p.p_partkey DESC, total_supply_cost DESC
LIMIT 50 OFFSET 0;
