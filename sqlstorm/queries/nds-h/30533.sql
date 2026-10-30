WITH  OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_custkey,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderstatus = 'F' 
),
CalculatedPrices AS (
    SELECT li.l_orderkey, SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_lineitem_price
    FROM lineitem li
    GROUP BY li.l_orderkey
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spending
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
FilteredSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost) < 5000
),
FinalSelection AS (
    SELECT c.c_name AS Customer_Name, oh.o_orderdate AS Order_Date,
           oh.o_totalprice AS Order_Total, ps.total_supplycost AS Supplier_Cost,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY oh.o_orderdate DESC) AS Rank
    FROM TopCustomers c
    JOIN OrderHierarchy oh ON c.c_custkey = oh.o_custkey
    JOIN FilteredSuppliers ps ON ps.total_supplycost < (SELECT AVG(total_supplycost) FROM FilteredSuppliers)
)
SELECT DISTINCT Customer_Name, Order_Date, Order_Total, Supplier_Cost
FROM FinalSelection
WHERE Rank <= 5 AND Supplier_Cost IS NOT NULL
ORDER BY Order_Total DESC, Order_Date;
