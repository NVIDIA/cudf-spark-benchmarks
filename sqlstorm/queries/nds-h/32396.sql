
WITH  CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '1996-01-01'
), SupplierCost AS (
    SELECT ps.ps_partkey, s.s_suppkey, s.s_name, ps.ps_supplycost,
           RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS rank
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
), HighValueOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000.00
)
SELECT co.c_name, COALESCE(SUM(hvo.total_value), 0) AS total_high_value,
       COUNT(DISTINCT co.o_orderkey) AS order_count,
       AVG(sc.ps_supplycost) AS avg_supplier_cost,
       MAX(sc.ps_supplycost) AS max_supplier_cost,
       MIN(sc.ps_supplycost) AS min_supplier_cost,
       STRING_AGG(DISTINCT CONCAT(sc.s_name, ' (', sc.ps_supplycost, ')')) AS suppliers_info
FROM CustomerOrders co
LEFT JOIN HighValueOrders hvo ON co.o_orderkey = hvo.o_orderkey
LEFT JOIN SupplierCost sc ON co.o_orderkey = sc.ps_partkey
WHERE co.rn = 1
GROUP BY co.c_name
ORDER BY total_high_value DESC;
