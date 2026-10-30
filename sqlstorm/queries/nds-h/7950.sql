
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, c.c_name
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
), OrderLineInfo AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value
    FROM lineitem l
    GROUP BY l.l_orderkey
), FinalReport AS (
    SELECT hv.o_orderkey, hv.o_totalprice, hv.c_name, rs.s_name, rs.total_supply_value, oli.total_line_value
    FROM HighValueOrders hv
    JOIN RankedSuppliers rs ON hv.o_orderkey = rs.s_suppkey
    JOIN OrderLineInfo oli ON hv.o_orderkey = oli.l_orderkey
)
SELECT o.o_orderkey, o.o_totalprice, o.c_name, s.s_name, s.total_supply_value, li.total_line_value
FROM FinalReport o
JOIN RankedSuppliers s ON o.s_name = s.s_name
JOIN OrderLineInfo li ON o.o_orderkey = li.l_orderkey
WHERE s.total_supply_value > 100000
ORDER BY o.o_totalprice DESC, s.total_supply_value ASC
LIMIT 50;
