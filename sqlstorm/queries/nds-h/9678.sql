WITH RegionSupplier AS (
    SELECT r.r_name, s.s_suppkey, s.s_name, s.s_acctbal
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE r.r_name IN ('NORTH AMERICA', 'EUROPE')
), 
HighValueCustomer AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal
    FROM customer c
    WHERE c.c_acctbal > 10000
), 
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
), 
SupplierStats AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_available_qty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
)
SELECT r.s_name AS supplier_name,
       r.s_acctbal AS supplier_account_balance,
       hc.c_name AS high_value_customer,
       od.total_revenue AS customer_order_revenue,
       ss.total_available_qty AS supplier_total_available_qty,
       ss.avg_supply_cost AS supplier_average_supply_cost
FROM RegionSupplier r
JOIN HighValueCustomer hc ON r.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_retailprice > 50))
JOIN OrderDetails od ON od.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O')
JOIN SupplierStats ss ON ss.ps_suppkey = r.s_suppkey
WHERE ss.avg_supply_cost < 20.00
ORDER BY od.total_revenue DESC, r.s_acctbal DESC;
