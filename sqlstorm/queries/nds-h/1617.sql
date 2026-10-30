WITH SupplierData AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COALESCE(SUM(ps.ps_supplycost * ps.ps_availqty), 0) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
HighValueSuppliers AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name,
        sd.s_acctbal,
        sd.total_supply_cost,
        ROW_NUMBER() OVER (ORDER BY sd.total_supply_cost DESC) AS rn
    FROM SupplierData sd
    WHERE sd.total_supply_cost > 1000.00
),
FeaturedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY o.o_orderkey, o.o_custkey, o.o_totalprice, o.o_orderdate
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
),
CombinedResults AS (
    SELECT 
        hs.s_suppkey,
        hs.s_name,
        hs.total_supply_cost,
        fo.o_orderkey,
        fo.order_revenue
    FROM HighValueSuppliers hs
    FULL OUTER JOIN FeaturedOrders fo ON hs.s_suppkey = fo.o_custkey
)
SELECT 
    cr.s_name,
    cr.total_supply_cost,
    cr.order_revenue,
    CASE 
        WHEN cr.s_suppkey IS NULL THEN 'No Supplier'
        ELSE cr.s_name
    END AS supplier_status,
    COALESCE(cr.order_revenue, 0) AS actual_order_revenue
FROM CombinedResults cr
ORDER BY cr.total_supply_cost DESC NULLS LAST, cr.order_revenue DESC NULLS LAST
LIMIT 50;