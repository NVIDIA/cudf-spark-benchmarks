WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
), CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
), LineItemAggregation AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue, COUNT(*) AS total_items
    FROM lineitem l
    WHERE l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1997-12-31'
    GROUP BY l.l_orderkey
), RevenueBySupplier AS (
    SELECT sd.s_suppkey, sd.s_name, SUM(la.revenue) AS total_revenue
    FROM SupplierDetails sd
    JOIN lineitem l ON sd.s_suppkey = l.l_suppkey
    JOIN LineItemAggregation la ON l.l_orderkey = la.l_orderkey
    GROUP BY sd.s_suppkey, sd.s_name
)
SELECT r.r_name, SUM(rb.total_revenue) AS total_revenue
FROM RevenueBySupplier rb
JOIN nation n ON rb.s_suppkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
GROUP BY r.r_name
ORDER BY total_revenue DESC
LIMIT 10;