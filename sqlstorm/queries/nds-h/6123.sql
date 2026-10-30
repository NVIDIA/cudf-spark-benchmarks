WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        sps.s_suppkey,
        sps.s_name,
        sps.total_supply_cost,
        sps.part_count,
        RANK() OVER (ORDER BY sps.total_supply_cost DESC) as supplier_rank
    FROM SupplierParts sps
)
SELECT 
    ts.s_suppkey,
    ts.s_name,
    ts.total_supply_cost,
    ts.part_count,
    SUM(o.o_totalprice) AS total_ordered_value
FROM TopSuppliers ts
JOIN orders o ON ts.s_suppkey = o.o_custkey
WHERE ts.supplier_rank <= 10
GROUP BY ts.s_suppkey, ts.s_name, ts.total_supply_cost, ts.part_count
ORDER BY total_ordered_value DESC;
