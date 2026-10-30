WITH SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT l.l_orderkey) AS total_orders,
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_order_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
),
HighValueSuppliers AS (
    SELECT 
        sp.s_suppkey,
        sp.s_name,
        sp.total_supply_cost,
        sp.total_orders,
        sp.avg_order_value,
        RANK() OVER (ORDER BY sp.avg_order_value DESC) AS rank_value
    FROM SupplierPerformance sp
    WHERE sp.total_orders > 0
),
NationDetails AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    hd.s_suppkey,
    hd.s_name,
    hd.total_supply_cost,
    hd.total_orders,
    hd.avg_order_value,
    nd.n_name,
    nd.supplier_count
FROM HighValueSuppliers hd
JOIN NationDetails nd ON hd.s_suppkey = (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    WHERE ps.ps_partkey IN (
        SELECT l.l_partkey 
        FROM lineitem l 
        WHERE l.l_returnflag = 'R' 
        AND l.l_shipdate >= DATE '1997-01-01'
    )
    LIMIT 1
)
WHERE hd.rank_value <= 10
UNION ALL
SELECT
    NULL AS s_suppkey,
    'Total Average' AS s_name,
    AVG(total_supply_cost) AS total_supply_cost,
    NULL AS total_orders,
    AVG(avg_order_value) AS avg_order_value,
    NULL AS n_name,
    NULL AS supplier_count
FROM HighValueSuppliers;