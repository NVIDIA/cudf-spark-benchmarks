
WITH RankedOrders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           o.o_totalprice,
           o.o_orderstatus,
           c.c_name,
           c.c_acctbal,
           DENSE_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= DATE '1996-01-01'
      AND o.o_orderdate < DATE '1997-01-01'
),
TopCustomers AS (
    SELECT r.r_name AS region,
           n.n_name AS nation,
           c.c_name AS customer_name,
           o.o_totalprice
    FROM RankedOrders o
    JOIN customer c ON o.o_orderkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE o.rank <= 5
)
SELECT region,
       nation,
       COUNT(customer_name) AS num_customers,
       SUM(o_totalprice) AS total_sales,
       AVG(o_totalprice) AS avg_sales,
       MAX(o_totalprice) AS max_sale
FROM TopCustomers
GROUP BY region, nation
ORDER BY total_sales DESC, nation ASC;
