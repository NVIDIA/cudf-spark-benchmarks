WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
OrderLineItems AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_item_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipmode = 'AIR'
    GROUP BY o.o_orderkey
),
RegionAnalysis AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS total_nations,
        SUM(l.l_quantity) AS total_line_item_quantity
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY r.r_name
)
SELECT 
    sp.s_name AS supplier_name,
    co.c_name AS customer_name,
    ra.r_name AS region_name,
    sp.total_available_quantity,
    sp.total_supply_cost,
    co.total_orders,
    co.total_spent,
    ra.total_nations,
    ra.total_line_item_quantity
FROM SupplierParts sp
JOIN CustomerOrders co ON sp.s_suppkey = co.c_custkey
JOIN RegionAnalysis ra ON ra.total_nations > 5
ORDER BY sp.total_supply_cost DESC, co.total_spent DESC
LIMIT 100;
