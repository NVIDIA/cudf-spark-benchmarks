WITH SupplierRegion AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name, r.r_name AS region_name, s.s_acctbal
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
PartSupplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, p.p_name, p.p_brand, p.p_retailprice, 
           ps.ps_availqty, ps.ps_supplycost, s.s_name AS supplier_name
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN SupplierRegion s ON ps.ps_suppkey = s.s_suppkey
),
OrderLine AS (
    SELECT o.o_orderkey, o.o_orderdate, li.l_quantity, li.l_extendedprice, 
           li.l_discount, li.l_tax, ps.p_name AS part_name, ps.supplier_name,
           o.o_totalprice
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    JOIN PartSupplier ps ON li.l_partkey = ps.ps_partkey
)
SELECT ol.part_name, ol.supplier_name, 
       SUM(ol.l_quantity) AS total_quantity,
       SUM(ol.l_extendedprice) AS total_extended_price,
       AVG(ol.l_discount) AS avg_discount,
       AVG(ol.l_tax) AS avg_tax,
       COUNT(DISTINCT ol.o_orderkey) AS order_count,
       MIN(ol.o_orderdate) AS first_order_date,
       MAX(ol.o_orderdate) AS last_order_date
FROM OrderLine ol
WHERE ol.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY ol.part_name, ol.supplier_name
ORDER BY total_extended_price DESC
LIMIT 100;