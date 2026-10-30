WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
),
CustomerNation AS (
    SELECT c.c_custkey, n.n_name AS nation_name
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
),
FinalResults AS (
    SELECT cd.nation_name, SUM(od.total_order_value) AS total_sales,
           COUNT(DISTINCT od.o_orderkey) AS total_orders, 
           SUM(sd.total_supply_cost) AS total_supply_cost
    FROM CustomerNation cd
    JOIN OrderDetails od ON cd.c_custkey = od.o_custkey
    JOIN SupplierDetails sd ON cd.c_custkey = sd.s_nationkey
    GROUP BY cd.nation_name
)
SELECT nation_name, total_sales, total_orders, total_supply_cost
FROM FinalResults
ORDER BY total_sales DESC, nation_name ASC;
