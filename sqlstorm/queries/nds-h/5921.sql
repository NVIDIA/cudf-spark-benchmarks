WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name, r.r_name AS region_name,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name, r.r_name
),
OrderStatistics AS (
    SELECT o.o_orderkey, o.o_orderstatus, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01'
    GROUP BY o.o_orderkey, o.o_orderstatus
)
SELECT sd.nation_name, sd.region_name, COUNT(DISTINCT os.o_orderkey) AS order_count,
       SUM(sd.total_supply_cost) AS total_supplier_cost, 
       SUM(os.total_revenue) AS total_sales_revenue
FROM SupplierDetails sd
LEFT JOIN OrderStatistics os ON sd.s_suppkey = os.o_orderkey
WHERE sd.total_supply_cost > 10000
GROUP BY sd.nation_name, sd.region_name
ORDER BY total_sales_revenue DESC, order_count DESC
LIMIT 10;