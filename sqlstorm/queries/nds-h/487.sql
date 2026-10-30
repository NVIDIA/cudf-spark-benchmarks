
WITH RegionNation AS (
    SELECT 
        r.r_regionkey,
        r.r_name AS region_name,
        n.n_name AS nation_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey, r.r_name, n.n_name
),
PartSupplierStats AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
OrderTotals AS (
    SELECT 
        o.o_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01'
    GROUP BY o.o_custkey
),
CustomerPerformance AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(ot.total_spent, 0) AS total_spent,
        COALESCE(ot.order_count, 0) AS order_count,
        CASE 
            WHEN COALESCE(ot.total_spent, 0) > 10000 THEN 'High Value'
            WHEN COALESCE(ot.total_spent, 0) BETWEEN 5000 AND 10000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_segment
    FROM customer c
    LEFT JOIN OrderTotals ot ON c.c_custkey = ot.o_custkey
),
SupplierPartRegion AS (
    SELECT 
        sp.ps_partkey,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        sp.ps_supplycost
    FROM partsupp sp
    JOIN supplier s ON sp.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    cp.c_name,
    rp.region_name,
    rp.nation_name,
    SUM(sp.ps_supplycost) AS total_supply_cost,
    SUM(COALESCE(ps.total_available_quantity, 0)) AS total_available_quantity,
    cp.customer_segment
FROM CustomerPerformance cp
JOIN RegionNation rp ON cp.c_custkey = rp.supplier_count
LEFT JOIN PartSupplierStats ps ON cp.c_custkey = ps.ps_partkey
LEFT JOIN SupplierPartRegion sp ON cp.c_custkey = sp.ps_partkey
WHERE cp.order_count > 1 
AND rp.supplier_count > 0
GROUP BY cp.c_name, rp.region_name, rp.nation_name, cp.customer_segment
HAVING SUM(sp.ps_supplycost) > 5000
ORDER BY total_supply_cost DESC, cp.c_name;
