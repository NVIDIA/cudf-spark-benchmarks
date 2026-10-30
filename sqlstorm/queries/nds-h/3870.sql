WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        o.o_custkey,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS order_count
    FROM orders o
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_custkey
),
RankedSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.total_supply_cost,
        ss.part_count,
        DENSE_RANK() OVER (ORDER BY ss.total_supply_cost DESC) AS cost_rank
    FROM SupplierStats ss
)
SELECT 
    rs.s_suppkey,
    rs.s_name,
    rs.total_supply_cost,
    rs.part_count,
    COALESCE(os.total_order_value, 0) AS total_order_value,
    COALESCE(os.order_count, 0) AS order_count
FROM RankedSuppliers rs
LEFT JOIN OrderSummary os ON rs.s_suppkey = os.o_custkey
WHERE rs.part_count > 5
  AND rs.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierStats)
  OR os.order_count < 2
ORDER BY rs.cost_rank, total_order_value DESC;
