WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, n.n_name AS nation_name, r.r_name AS region_name, 
           LENGTH(s.s_comment) AS comment_length, s.s_acctbal
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_size, p.p_retailprice, 
           LENGTH(p.p_comment) AS comment_length
    FROM part p
    WHERE p.p_type LIKE 'b%a%'
),
CombinedDetails AS (
    SELECT sd.s_suppkey, sd.s_name, sd.nation_name, sd.region_name, 
           pd.p_partkey, pd.p_name, pd.p_brand, pd.p_type, pd.p_size, pd.p_retailprice,
           sd.comment_length AS supplier_comment_length, pd.comment_length AS part_comment_length
    FROM SupplierDetails sd
    JOIN partsupp ps ON sd.s_suppkey = ps.ps_suppkey
    JOIN PartDetails pd ON ps.ps_partkey = pd.p_partkey
)
SELECT cd.nation_name, cd.region_name, COUNT(DISTINCT cd.s_suppkey) AS supplier_count, 
       AVG(cd.supplier_comment_length) AS avg_supplier_comment_length, 
       AVG(cd.part_comment_length) AS avg_part_comment_length, 
       SUM(cd.p_retailprice) AS total_retail_value
FROM CombinedDetails cd
GROUP BY cd.nation_name, cd.region_name
HAVING COUNT(DISTINCT cd.p_partkey) > 5
ORDER BY total_retail_value DESC;
