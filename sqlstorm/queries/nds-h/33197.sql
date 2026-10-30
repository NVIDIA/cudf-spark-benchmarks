
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_nationkey, s_suppkey, s_name, 1 AS level
    FROM supplier
    WHERE s_suppkey IN (SELECT MIN(s_suppkey) FROM supplier GROUP BY s_nationkey)
    UNION ALL
    SELECT s.s_nationkey, s.s_suppkey, s.s_name, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey 
    WHERE sh.level < 5
), 
EligibleOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01' 
      AND o.o_orderdate < DATE '1997-10-01'
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_totalprice
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 50000
),
NationsInfo AS (
    SELECT n.n_name, 
           COALESCE(SUM(o.o_totalprice), 0) AS total_spending,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_name
)
SELECT 
    nh.n_name, 
    nh.total_spending,
    nh.order_count,
    th.s_name AS top_supplier,
    th.total_cost,
    ROW_NUMBER() OVER (PARTITION BY nh.n_name ORDER BY nh.total_spending DESC) AS ranking
FROM NationsInfo nh
JOIN TopSuppliers th ON nh.order_count > 0
WHERE nh.total_spending IS NOT NULL
ORDER BY nh.total_spending DESC, ranking
LIMIT 10 OFFSET 5;
