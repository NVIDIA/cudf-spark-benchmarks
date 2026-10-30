WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           (SELECT COUNT(*) FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey) AS part_supply_count
    FROM supplier s
),
CustomerDetails AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, 
           (SELECT COUNT(*) FROM orders o WHERE o.o_custkey = c.c_custkey) AS order_count
    FROM customer c
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderstatus, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           COUNT(l.l_orderkey) AS line_item_count,
           MAX(o.o_orderdate) AS last_order_date
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderstatus
),
NationRegion AS (
    SELECT n.n_nationkey, n.n_name, r.r_regionkey, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    sd.s_name AS supplier_name,
    cd.c_name AS customer_name,
    nr.r_name AS region_name,
    od.total_sales,
    od.line_item_count,
    sd.part_supply_count,
    od.last_order_date
FROM SupplierDetails sd
JOIN CustomerDetails cd ON sd.s_nationkey = cd.c_nationkey
JOIN OrderDetails od ON cd.c_custkey = od.o_custkey
JOIN NationRegion nr ON cd.c_nationkey = nr.n_nationkey
WHERE 
    sd.s_acctbal > 50000 AND 
    od.total_sales > 10000 AND 
    nr.r_name LIKE 'Amer%' 
ORDER BY 
    sd.s_name, cd.c_name;
