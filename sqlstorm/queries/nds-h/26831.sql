WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_phone, s.s_acctbal, 
           LENGTH(s.s_comment) AS comment_length, 
           SUBSTRING(s.s_comment, 1, 15) AS short_comment
    FROM supplier s 
    WHERE s.s_acctbal > 10000
), 
CustomerDetails AS (
    SELECT c.c_custkey, c.c_name, c.c_address, c.c_nationkey, c.c_phone, 
           LENGTH(c.c_comment) AS comment_length, 
           SUBSTRING(c.c_comment, 1, 15) AS short_comment
    FROM customer c 
    WHERE c.c_acctbal > 5000
), 
RegionInfo AS (
    SELECT r.r_regionkey, r.r_name, 
           (SELECT COUNT(*) FROM nation n WHERE n.n_regionkey = r.r_regionkey) AS nation_count
    FROM region r
)
SELECT s.s_name AS supplier_name, s.short_comment AS supplier_comment, 
       c.c_name AS customer_name, c.short_comment AS customer_comment, 
       r.r_name AS region_name, r.nation_count
FROM SupplierDetails s 
JOIN CustomerDetails c ON s.s_nationkey = c.c_nationkey
JOIN RegionInfo r ON c.c_nationkey = r.r_regionkey
ORDER BY supplier_name, customer_name;
