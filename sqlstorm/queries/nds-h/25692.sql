WITH PartAggregates AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_mfgr, 
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_mfgr
),
SupplierRegions AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        n.n_name AS nation_name, 
        r.r_name AS region_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
OrderLineItems AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice) AS total_extended_price,
        COUNT(l.l_linenumber) AS number_of_line_items
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)

SELECT 
    pa.p_name, 
    pa.p_brand, 
    sr.nation_name, 
    sr.region_name, 
    co.total_orders, 
    oli.total_extended_price,
    oli.number_of_line_items,
    pa.total_avail_qty,
    pa.avg_supply_cost
FROM PartAggregates pa
JOIN SupplierRegions sr ON pa.p_partkey IN (SELECT DISTINCT ps.ps_partkey FROM partsupp ps JOIN supplier s ON ps.ps_suppkey = s.s_suppkey WHERE s.s_name LIKE '%Industrial%')
JOIN CustomerOrders co ON co.total_orders > 10
JOIN OrderLineItems oli ON oli.total_extended_price > 50000
WHERE pa.total_avail_qty > 100
ORDER BY pa.p_name, sr.region_name;
