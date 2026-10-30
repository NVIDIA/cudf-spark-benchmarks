
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) as rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0
), OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F' AND l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1997-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
), SupplierContribution AS (
    SELECT rs.s_suppkey, oss.total_revenue, COUNT(*) AS order_count
    FROM RankedSuppliers rs
    JOIN OrderSummary oss ON rs.s_suppkey = oss.o_orderkey
    GROUP BY rs.s_suppkey, oss.total_revenue
)
SELECT s.s_name, sc.order_count, SUM(sc.total_revenue) AS total_contribution
FROM supplier s
JOIN SupplierContribution sc ON s.s_suppkey = sc.s_suppkey
GROUP BY s.s_name, sc.order_count
HAVING SUM(sc.total_revenue) > 1000000
ORDER BY total_contribution DESC;
