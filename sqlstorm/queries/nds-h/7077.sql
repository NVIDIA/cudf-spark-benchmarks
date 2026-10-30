WITH RegionalSuppliers AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_name, r.r_name, s.s_suppkey
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(DISTINCT l.l_partkey) AS line_item_count
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
    GROUP BY o.o_orderkey, c.c_custkey
)
SELECT 
    rs.region_name,
    rs.nation_name,
    COUNT(DISTINCT od.o_orderkey) AS total_orders,
    SUM(od.total_order_value) AS total_revenue,
    SUM(rs.total_available_quantity) AS total_parts_available,
    SUM(rs.total_supply_cost) AS total_supply_cost
FROM RegionalSuppliers rs
JOIN OrderDetails od ON rs.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    WHERE ps.ps_partkey IN (SELECT DISTINCT l.l_partkey FROM lineitem l)
)
GROUP BY rs.region_name, rs.nation_name
ORDER BY total_revenue DESC, total_orders DESC;