WITH SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           CONCAT(UPPER(SUBSTRING(s.s_name, 1, 1)), LOWER(SUBSTRING(s.s_name, 2))) AS formatted_name,
           LENGTH(s.s_name) AS name_length
    FROM supplier s
), RegionNation AS (
    SELECT n.n_nationkey, n.n_name, r.r_name AS region_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
), PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_container, p.p_retailprice,
           REPLACE(p.p_comment, 'Use', 'Utilize') AS modified_comment
    FROM part p
), CustomerSummary AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_mktsegment,
           CASE
               WHEN c.c_acctbal < 500 THEN 'Low'
               WHEN c.c_acctbal BETWEEN 500 AND 1000 THEN 'Medium'
               ELSE 'High'
           END AS account_category
    FROM customer c
)
SELECT si.formatted_name, rn.n_name AS nation_name, rn.region_name, 
       pd.p_name, pd.modified_comment, cs.account_category,
       COUNT(DISTINCT o.o_orderkey) AS total_orders,
       SUM(li.l_extendedprice) AS total_extended_price,
       AVG(li.l_discount) AS avg_discount
FROM SupplierInfo si
JOIN partsupp ps ON si.s_suppkey = ps.ps_suppkey
JOIN PartDetails pd ON ps.ps_partkey = pd.p_partkey
JOIN RegionNation rn ON si.s_nationkey = rn.n_nationkey
JOIN lineitem li ON li.l_partkey = pd.p_partkey
JOIN orders o ON li.l_orderkey = o.o_orderkey
JOIN CustomerSummary cs ON o.o_custkey = cs.c_custkey
WHERE cs.account_category = 'High'
GROUP BY si.formatted_name, rn.n_name, rn.region_name, 
         pd.p_name, pd.modified_comment, cs.account_category
HAVING SUM(li.l_extendedprice) > 10000
ORDER BY total_extended_price DESC, si.formatted_name ASC;
