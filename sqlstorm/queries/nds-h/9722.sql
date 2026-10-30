WITH SupplierStats AS (
    SELECT 
        s.s_name,
        n.n_name AS nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT p.p_partkey) AS total_parts_supplied
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_name, n.n_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS total_line_items
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT 
    ss.s_name,
    ss.nation,
    ss.total_supply_value,
    os.total_revenue,
    os.total_line_items
FROM SupplierStats ss
JOIN OrderStats os ON ss.total_parts_supplied = os.total_line_items
WHERE ss.total_supply_value > 1000000
ORDER BY os.total_revenue DESC
LIMIT 10;