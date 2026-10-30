WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
FilteredOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, c.c_nationkey
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-02-01'
),
OrderLineItems AS (
    SELECT li.l_orderkey, SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_price
    FROM lineitem li
    JOIN FilteredOrders fo ON li.l_orderkey = fo.o_orderkey
    GROUP BY li.l_orderkey
),
TotalRevenueBySupplier AS (
    SELECT rs.s_suppkey, rs.s_name, SUM(oli.total_price) AS total_revenue
    FROM RankedSuppliers rs
    JOIN partsupp ps ON rs.s_suppkey = ps.ps_suppkey
    JOIN lineitem li ON ps.ps_partkey = li.l_partkey
    JOIN OrderLineItems oli ON li.l_orderkey = oli.l_orderkey
    GROUP BY rs.s_suppkey, rs.s_name
)
SELECT s.s_name, COALESCE(tr.total_revenue, 0) AS revenue, rs.total_supply_cost
FROM RankedSuppliers rs
LEFT JOIN TotalRevenueBySupplier tr ON rs.s_suppkey = tr.s_suppkey
JOIN supplier s ON rs.s_suppkey = s.s_suppkey
ORDER BY revenue DESC, rs.total_supply_cost DESC
LIMIT 10;