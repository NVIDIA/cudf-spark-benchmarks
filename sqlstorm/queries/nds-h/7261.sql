
WITH RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, 
           p.p_size, p.p_retailprice, p.p_comment, 
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
), 
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, 
           s.s_phone, s.s_acctbal, s.s_comment,
           n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
), 
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_address, c.c_nationkey, 
           o.o_orderkey, o.o_totalprice, o.o_orderdate, 
           o.o_orderpriority, o.o_comment
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '1997-01-01'
), 
LineItemSummary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           SUM(l.l_quantity) AS total_quantity, COUNT(DISTINCT l.l_suppkey) AS unique_suppliers
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    co.c_name AS customer_name,
    rp.p_name AS part_name,
    rp.p_brand AS brand,
    rp.p_retailprice AS retail_price,
    so.nation_name AS supplier_nation,
    SUM(ls.total_sales) AS total_sales,
    COUNT(DISTINCT co.o_orderkey) AS number_of_orders
FROM CustomerOrders co
JOIN LineItemSummary ls ON co.o_orderkey = ls.l_orderkey
JOIN RankedParts rp ON rp.rank <= 5 
JOIN SupplierDetails so ON rp.p_partkey = so.s_suppkey 
WHERE co.o_orderpriority = 'High'
GROUP BY co.c_name, rp.p_name, rp.p_brand, rp.p_retailprice, so.nation_name
ORDER BY total_sales DESC
LIMIT 10;
