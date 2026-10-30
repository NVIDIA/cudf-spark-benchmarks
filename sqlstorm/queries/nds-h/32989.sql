
WITH  RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           RANK() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
TopSupplierParts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, 
           p.p_name, p.p_brand, p.p_retailprice
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_suppkey IN (SELECT s_suppkey FROM RankedSuppliers WHERE rank <= 5)
),
OrderStats AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
),
AverageRevenue AS (
    SELECT AVG(revenue) AS avg_revenue
    FROM OrderStats
),
TopOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, 
           CASE 
               WHEN o.o_totalprice > (SELECT avg_revenue FROM AverageRevenue) THEN 'Above Average'
               ELSE 'Below Average'
           END AS price_category
    FROM orders o
)
SELECT T.ps_partkey, T.p_name, T.p_brand, T.ps_availqty, 
       COALESCE(O.price_category, 'No Orders') AS order_category,
       SUM(T.ps_availqty) OVER (PARTITION BY T.p_brand) AS total_avail_qty_by_brand
FROM TopSupplierParts T
LEFT JOIN TopOrders O ON T.ps_suppkey = O.o_orderkey
WHERE T.ps_availqty > 0
ORDER BY T.p_brand, T.p_name;
