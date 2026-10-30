WITH SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
SalesData AS (
    SELECT c.c_nationkey, SUM(o.o_totalprice) AS total_sales
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_nationkey
),
NationStats AS (
    SELECT n.n_nationkey, n.n_name, r.r_name AS region_name,
           COALESCE(ss.total_supply_value, 0) AS total_supply_value,
           COALESCE(sd.total_sales, 0) AS total_sales
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN SupplierStats ss ON n.n_nationkey = ss.s_suppkey
    LEFT JOIN SalesData sd ON n.n_nationkey = sd.c_nationkey
)
SELECT ns.n_name, ns.region_name, ns.total_supply_value, ns.total_sales,
       CASE WHEN ns.total_sales > 0 THEN (ns.total_supply_value / ns.total_sales) ELSE 0 END AS supply_to_sales_ratio
FROM NationStats ns
ORDER BY ns.region_name ASC, ns.total_supply_value DESC;
