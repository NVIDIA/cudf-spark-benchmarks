WITH  OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderstatus, o_totalprice, o_orderdate,
           o_orderpriority, o_clerk, o_shippriority, 
           ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY o_orderdate DESC) AS rn
    FROM orders
), 
SupplierPricing AS (
    SELECT ps.ps_partkey, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey
),
LineItemSummary AS (
    SELECT l_orderkey, SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
    FROM lineitem
    GROUP BY l_orderkey
),
FinalResults AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(CASE WHEN o.o_orderstatus = 'O' THEN ls.total_revenue ELSE 0 END) AS open_orders_revenue,
        SUM(CASE WHEN o.o_orderstatus = 'F' THEN ls.total_revenue ELSE 0 END) AS fulfilled_orders_revenue,
        COALESCE(sp.avg_supplycost, 0) AS avg_supply_cost,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem li ON ps.ps_partkey = li.l_partkey
    LEFT JOIN LineItemSummary ls ON li.l_orderkey = ls.l_orderkey
    LEFT JOIN OrderHierarchy o ON ls.l_orderkey = o.o_orderkey
    LEFT JOIN SupplierPricing sp ON ps.ps_partkey = sp.ps_partkey
    GROUP BY n.n_name, sp.avg_supplycost
    HAVING COUNT(DISTINCT o.o_orderkey) > 5
)
SELECT 
    nation_name,
    open_orders_revenue,
    fulfilled_orders_revenue,
    avg_supply_cost,
    total_orders,
    CASE 
        WHEN open_orders_revenue > fulfilled_orders_revenue THEN 'Open Orders Lead'
        ELSE 'Fulfilled Orders Lead'
    END AS order_status_analysis
FROM FinalResults
ORDER BY nation_name;
