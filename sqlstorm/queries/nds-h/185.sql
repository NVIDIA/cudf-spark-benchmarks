WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1995-01-01'
),
SupplierCostSummary AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        COUNT(ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal > 5000
    GROUP BY ps.ps_partkey
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    COALESCE(s.total_supply_cost, 0) AS total_supply_cost,
    co.total_orders,
    co.avg_order_value,
    r.r_name AS region_name
FROM part p
LEFT JOIN SupplierCostSummary s ON p.p_partkey = s.ps_partkey
LEFT JOIN customer c ON c.c_custkey IN (
    SELECT DISTINCT o.o_custkey
    FROM orders o
    WHERE o.o_orderkey IN (
        SELECT o_orderkey FROM RankedOrders
        WHERE order_rank <= 10
    )
)
LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN CustomerOrderStats co ON co.c_custkey = c.c_custkey
WHERE p.p_retailprice > 20.00
  AND (p.p_comment LIKE '%important%' OR p.p_comment LIKE '%urgent%')
ORDER BY total_supply_cost DESC, avg_order_value DESC
LIMIT 100;