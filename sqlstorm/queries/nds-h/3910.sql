
WITH SupplierCosts AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01' 
      AND o.o_orderdate < DATE '1998-01-01' 
    GROUP BY o.o_orderkey, o.o_orderdate
),
NationRegion AS (
    SELECT n.n_nationkey, n.n_name, r.r_regionkey, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
RankedOrders AS (
    SELECT od.o_orderkey, od.o_orderdate, od.total_sales,
           RANK() OVER (PARTITION BY nr.r_regionkey ORDER BY od.total_sales DESC) AS sales_rank,
           nr.n_name AS nation_name
    FROM OrderDetails od
    JOIN customer c ON od.o_orderkey = c.c_custkey 
    JOIN NationRegion nr ON c.c_nationkey = nr.n_nationkey
)

SELECT n.n_name, SUM(r.total_supply_cost) AS total_cost,
       COUNT(DISTINCT ro.o_orderkey) AS total_orders,
       AVG(ro.total_sales) AS avg_order_value,
       CASE WHEN COUNT(DISTINCT ro.o_orderkey) > 0 THEN SUM(r.total_supply_cost) / COUNT(DISTINCT ro.o_orderkey) ELSE NULL END AS cost_per_order
FROM RankedOrders ro
RIGHT JOIN SupplierCosts r ON ro.nation_name = CAST(r.s_suppkey AS STRING)
JOIN NationRegion n ON ro.nation_name = n.n_name
GROUP BY n.n_name
HAVING SUM(r.total_supply_cost) IS NOT NULL
ORDER BY total_orders DESC;
