
WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, COUNT(p.ps_partkey) AS total_parts
    FROM supplier s
    JOIN partsupp p ON s.s_suppkey = p.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice
),
NationRevenue AS (
    SELECT n.n_nationkey, n.n_name, SUM(co.total_revenue) AS nation_revenue
    FROM CustomerOrders co
    JOIN customer c ON co.c_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT rg.r_name AS region_name, SUM(nr.nation_revenue) AS total_region_revenue
FROM nation n
JOIN region rg ON n.n_regionkey = rg.r_regionkey
JOIN NationRevenue nr ON n.n_nationkey = nr.n_nationkey
GROUP BY rg.r_name
ORDER BY total_region_revenue DESC
LIMIT 10;
