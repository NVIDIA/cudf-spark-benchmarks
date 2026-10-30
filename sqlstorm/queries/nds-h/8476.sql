WITH SupplierStats AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
PartStats AS (
    SELECT p.p_partkey, AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1997-12-31'
    GROUP BY p.p_partkey
),
OrderStats AS (
    SELECT o.o_orderkey, o.o_orderstatus, SUM(l.l_extendedprice) AS total_price, COUNT(l.l_linenumber) AS total_lines
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus
)
SELECT r.r_name AS region_name, COUNT(DISTINCT n.n_nationkey) AS nation_count,
       SUM(ss.total_supply_cost) AS total_supply_cost,
       AVG(ps.avg_price) AS avg_price_per_part,
       SUM(os.total_price) AS total_order_value,
       AVG(os.total_lines) AS avg_lines_per_order
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN SupplierStats ss ON n.n_nationkey = ss.s_suppkey
LEFT JOIN PartStats ps ON n.n_nationkey = ps.p_partkey
LEFT JOIN OrderStats os ON n.n_nationkey = os.o_orderkey
GROUP BY r.r_name
ORDER BY total_supply_cost DESC, avg_price_per_part DESC;