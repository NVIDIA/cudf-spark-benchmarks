WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1996-01-01' 
      AND o.o_orderdate < DATE '1997-01-01'
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(ps_supplycost) FROM partsupp)
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 5
),
MonthlySales AS (
    SELECT EXTRACT(YEAR FROM o.o_orderdate) AS order_year,
           EXTRACT(MONTH FROM o.o_orderdate) AS order_month,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY order_year, order_month
)
SELECT r.o_orderkey, r.o_orderdate, r.o_totalprice, c.c_name, t.s_name, ms.total_sales
FROM RankedOrders r
JOIN CustomerOrders c ON r.o_orderkey = c.c_custkey
LEFT JOIN TopSuppliers t ON t.total_supply_cost >= 200000
FULL OUTER JOIN MonthlySales ms ON ms.order_year = EXTRACT(YEAR FROM r.o_orderdate) 
                                   AND ms.order_month = EXTRACT(MONTH FROM r.o_orderdate)
WHERE r.order_rank <= 10 
  AND (c.order_count IS NOT NULL OR t.s_name IS NULL)
ORDER BY r.o_totalprice DESC, ms.total_sales DESC;