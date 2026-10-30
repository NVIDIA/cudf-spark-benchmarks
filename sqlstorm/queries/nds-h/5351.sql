
WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),

PartSuppliers AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost
    FROM partsupp ps
    JOIN SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
    WHERE sd.s_acctbal > 1000
),

CustomerOrders AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
),

DetailedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, ps.ps_supplycost, 
           (p.p_retailprice - ps.ps_supplycost) AS profit_margin
    FROM part p
    JOIN PartSuppliers ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size IN (10, 20, 30)
    AND (p.p_retailprice - ps.ps_supplycost) > 0
),

FinalReport AS (
    SELECT cd.o_orderkey, cd.o_custkey, dp.p_partkey, dp.p_name, dp.profit_margin,
           sd.nation_name, cd.total_value
    FROM CustomerOrders cd
    JOIN DetailedParts dp ON cd.o_orderkey = dp.p_partkey
    JOIN SupplierDetails sd ON dp.ps_supplycost < 100
)

SELECT nation_name, COUNT(DISTINCT o_orderkey) AS order_count, SUM(total_value) AS total_sales 
FROM FinalReport 
GROUP BY nation_name 
ORDER BY total_sales DESC;
