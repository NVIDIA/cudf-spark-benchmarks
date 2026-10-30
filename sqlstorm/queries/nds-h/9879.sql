WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), CustomerOrderSummary AS (
    SELECT c.c_custkey, c.c_name, COUNT(DISTINCT o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY c.c_custkey, c.c_name
), TopRegions AS (
    SELECT n.n_regionkey, r.r_name, SUM(o.o_totalprice) AS region_total
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_regionkey, r.r_name
    ORDER BY region_total DESC
    LIMIT 5
), InventoryStatus AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_availqty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(ps.ps_availqty) > 0
)
SELECT cr.c_name AS customer_name,
       cr.order_count,
       cr.total_spent,
       trs.r_name AS region_name,
       iss.p_name AS part_name,
       iss.total_availqty,
       iss.avg_supply_cost,
       rs.total_cost AS supplier_cost
FROM CustomerOrderSummary cr
JOIN TopRegions trs ON cr.total_spent > trs.region_total * 0.1
JOIN InventoryStatus iss ON cr.total_spent > (SELECT AVG(total_spent) FROM CustomerOrderSummary)
JOIN RankedSuppliers rs ON rs.total_cost < cr.total_spent * 0.5
ORDER BY cr.total_spent DESC, rs.total_cost ASC;