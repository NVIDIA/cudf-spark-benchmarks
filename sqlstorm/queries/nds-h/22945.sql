WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        1 AS level
    FROM supplier s
    UNION ALL
    SELECT 
        s.s_suppkey,
        sh.s_name,
        sh.s_nationkey,
        sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey
    WHERE s.s_nationkey IS NOT NULL
)

, PriceSummary AS (
    SELECT 
        p.p_partkey,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_available_qty
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
)

, OrderTotals AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price_after_discount,
        CASE 
            WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) = 0 THEN NULL
            ELSE SUM(l.l_extendedprice * (1 - l.l_discount)) / COUNT(l.l_orderkey)
        END AS avg_price_per_order
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)

SELECT 
    p.p_partkey,
    p.p_name,
    ps.avg_supply_cost,
    os.total_price_after_discount,
    n.n_name AS supplier_nation,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.avg_supply_cost DESC) AS rank_by_cost,
    CASE 
        WHEN ps.total_available_qty IS NULL THEN 'None'
        ELSE CAST(ps.total_available_qty AS STRING) || ' units available'
    END AS availability_description
FROM PriceSummary ps
JOIN part p ON p.p_partkey = ps.p_partkey
LEFT JOIN supplier s ON s.s_nationkey = (SELECT n.n_nationkey 
                                          FROM nation n 
                                          WHERE n.n_name = 'USA'
                                          ORDER BY n.n_nationkey LIMIT 1)
LEFT JOIN OrderTotals os ON os.o_orderkey IN (SELECT o.o_orderkey 
                                              FROM orders o 
                                              WHERE o.o_orderkey = (SELECT MIN(o_orderkey) 
                                                                     FROM orders))
LEFT JOIN nation n ON n.n_nationkey = s.s_nationkey
WHERE ps.avg_supply_cost > (SELECT AVG(total_price_after_discount) 
                             FROM OrderTotals)
ORDER BY p.p_partkey, rank_by_cost;
