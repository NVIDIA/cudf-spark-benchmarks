
WITH SupplierAgg AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
CustomerOrders AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
NationAggregate AS (
    SELECT n.n_nationkey, SUM(ca.total_spent) AS total_sales, COUNT(DISTINCT ca.c_custkey) AS total_customers
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN CustomerOrders ca ON c.c_custkey = ca.c_custkey
    GROUP BY n.n_nationkey
),
RegionSales AS (
    SELECT r.r_regionkey, SUM(na.total_sales) AS region_sales, SUM(na.total_customers) AS region_customers
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN NationAggregate na ON n.n_nationkey = na.n_nationkey
    GROUP BY r.r_regionkey
)
SELECT r.r_name, rs.region_sales, rs.region_customers, 
       (SELECT COUNT(DISTINCT s.s_suppkey) 
        FROM supplier s 
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey) AS total_suppliers
FROM RegionSales rs
JOIN region r ON rs.r_regionkey = r.r_regionkey
ORDER BY rs.region_sales DESC, rs.region_customers ASC;
