WITH SupplierCost AS (
    SELECT ps.ps_suppkey, SUM(ps.ps_supplycost * l.l_quantity) AS total_cost
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1997-12-31'
    GROUP BY ps.ps_suppkey
), RegionSummary AS (
    SELECT r.r_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count, SUM(sc.total_cost) AS total_supplier_cost
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN SupplierCost sc ON s.s_suppkey = sc.ps_suppkey
    GROUP BY r.r_name
), CustomerOrderSummary AS (
    SELECT c.c_nationkey, SUM(o.o_totalprice) AS total_revenue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31'
    GROUP BY c.c_nationkey
)
SELECT r.r_name, rs.supplier_count, rs.total_supplier_cost, cos.total_revenue
FROM RegionSummary rs
JOIN region r ON r.r_name = rs.r_name
LEFT JOIN CustomerOrderSummary cos ON r.r_regionkey = cos.c_nationkey
ORDER BY rs.total_supplier_cost DESC, cos.total_revenue DESC;