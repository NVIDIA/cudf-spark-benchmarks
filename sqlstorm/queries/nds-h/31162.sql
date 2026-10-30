WITH  TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_cost DESC
    LIMIT 5
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rnk
    FROM orders o
    WHERE o.o_totalprice > 1000
),
PartStatus AS (
    SELECT l.l_orderkey, COUNT(*) AS line_count, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    WHERE l.l_returnflag = 'N' AND l.l_shipdate < cast('1998-10-01' as date) - INTERVAL '30' DAY
    GROUP BY l.l_orderkey
),
FilteredSupply AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice > 50.00
    GROUP BY ps.ps_partkey
)
SELECT s.s_name, SUM(l.l_quantity) AS total_quantity, COUNT(DISTINCT o.o_orderkey) AS order_count
FROM supplier s
LEFT OUTER JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT OUTER JOIN lineitem l ON ps.ps_partkey = l.l_partkey
LEFT OUTER JOIN OrderDetails o ON l.l_orderkey = o.o_orderkey
JOIN TopSuppliers ts ON s.s_suppkey = ts.s_suppkey
WHERE l.l_shipmode IN ('AIR', 'TRUCK')
  AND o.order_rnk <= 10
  AND (o.o_totalprice IS NOT NULL OR l.l_discount IS NULL) 
  AND l.l_quantity > (
      SELECT AVG(l2.l_quantity) FROM lineitem l2 WHERE l2.l_shipmode = l.l_shipmode
  )
GROUP BY s.s_name
ORDER BY total_quantity DESC, order_count DESC;