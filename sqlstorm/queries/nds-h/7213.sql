WITH RankedPartSuppliers AS (
    SELECT ps.ps_partkey, 
           ps.ps_suppkey, 
           s.s_name, 
           ps.ps_availqty, 
           ps.ps_supplycost, 
           ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS rank
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
), 
TotalOrderValue AS (
    SELECT o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1996-01-01'
    GROUP BY o.o_orderkey
),
HighValueOrders AS (
    SELECT *,
           RANK() OVER (ORDER BY total_value DESC) AS order_rank
    FROM TotalOrderValue
    WHERE total_value > 10000
), 
TopSuppliers AS (
    SELECT ps_partkey, 
           s_name, 
           ps_availqty, 
           ps_supplycost
    FROM RankedPartSuppliers
    WHERE rank <= 5
)
SELECT o.o_orderkey, 
       o.total_value, 
       ts.s_name, 
       ts.ps_availqty, 
       ts.ps_supplycost
FROM HighValueOrders o
JOIN TopSuppliers ts ON o.o_orderkey = ts.ps_partkey
ORDER BY o.total_value DESC, ts.ps_supplycost ASC
LIMIT 50;