
WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
PartSupplierInfo AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_avail_qty
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    r.r_name AS Region,
    n.n_name AS Nation,
    s.s_name AS Supplier,
    p.p_name AS Part_Name,
    COUNT(DISTINCT lo.l_orderkey) AS Total_Orders,
    AVG(lo.l_discount) AS Average_Discount,
    SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS Revenue,
    COALESCE(NULLIF(MAX(o.o_totalprice), 0), -1) AS Max_Order_Value,
    ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(lo.l_extendedprice * (1 - lo.l_discount)) DESC) AS Revenue_Rank
FROM lineitem lo
JOIN orders o ON lo.l_orderkey = o.o_orderkey
JOIN partsupp ps ON lo.l_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN TopCustomers tc ON o.o_custkey = tc.c_custkey
WHERE lo.l_shipdate < DATE '1998-10-01' - INTERVAL '30 days'
  AND (tc.total_spent IS NOT NULL OR r.r_name IS NOT NULL)
GROUP BY r.r_name, n.n_name, s.s_name, p.p_name, r.r_regionkey
HAVING SUM(lo.l_extendedprice * (1 - lo.l_discount)) > 1000
ORDER BY Revenue DESC
LIMIT 50;
