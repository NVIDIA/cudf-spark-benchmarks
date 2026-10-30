WITH RegionalSuppliers AS (
    SELECT n.n_name AS nation_name, r.r_name AS region_name, s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_name, r.r_name, s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_totalprice, l.l_partkey, l.l_quantity, l.l_extendedprice, l.l_discount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31'
),
PriceCalculations AS (
    SELECT od.o_orderkey, SUM(od.l_extendedprice * (1 - od.l_discount)) AS adjusted_price
    FROM OrderDetails od
    GROUP BY od.o_orderkey
)
SELECT rs.region_name, rs.nation_name, COUNT(DISTINCT od.o_orderkey) AS order_count,
       SUM(pc.adjusted_price) AS total_adjusted_revenue, AVG(rs.total_supply_cost) AS avg_supply_cost
FROM RegionalSuppliers rs
LEFT JOIN PriceCalculations pc ON rs.s_suppkey = pc.o_orderkey
JOIN OrderDetails od ON pc.o_orderkey = od.o_orderkey
GROUP BY rs.region_name, rs.nation_name
ORDER BY total_adjusted_revenue DESC, order_count DESC;