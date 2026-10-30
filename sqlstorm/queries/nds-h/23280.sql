WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal IS NOT NULL
),
QualifiedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_discounted_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N' AND l.l_shipdate > '1997-01-01'
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate
),
SupplierOrderSummary AS (
    SELECT rs.s_suppkey, COUNT(DISTINCT qo.o_orderkey) AS order_count,
           AVG(qo.total_discounted_price) AS avg_discounted_price
    FROM RankedSuppliers rs
    LEFT JOIN partsupp ps ON rs.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN QualifiedOrders qo ON l.l_orderkey = qo.o_orderkey
    GROUP BY rs.s_suppkey
),
FinalReport AS (
    SELECT sos.s_suppkey, sos.order_count,
           CASE WHEN sos.order_count > 10 THEN 'High' ELSE 'Low' END AS order_volume,
           COALESCE(sos.avg_discounted_price, 0) AS avg_discounted_price
    FROM SupplierOrderSummary sos
    WHERE sos.order_count IS NOT NULL
)
SELECT r.r_name, fr.order_volume, AVG(fr.avg_discounted_price) AS avg_supplier_price
FROM FinalReport fr
JOIN supplier s ON fr.s_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
GROUP BY r.r_name, fr.order_volume
HAVING AVG(fr.avg_discounted_price) > (SELECT AVG(total_discounted_price) FROM QualifiedOrders)
ORDER BY r.r_name, fr.order_volume DESC
LIMIT 10 OFFSET 5;