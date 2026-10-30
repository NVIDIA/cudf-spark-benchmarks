WITH SupplierDetails AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_address, 
           s.s_phone, 
           n.n_name AS nation_name, 
           r.r_name AS region_name, 
           s.s_comment
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
), PartDetails AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_mfgr, 
           p.p_brand, 
           p.p_type, 
           p.p_size, 
           p.p_container, 
           p.p_retailprice, 
           p.p_comment
    FROM part p
    WHERE p.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
), LineItemSummary AS (
    SELECT l.l_partkey, 
           SUM(l.l_quantity) AS total_quantity, 
           AVG(l.l_extendedprice) AS average_price, 
           MAX(l.l_discount) AS max_discount 
    FROM lineitem l
    GROUP BY l.l_partkey
), CombinedData AS (
    SELECT pd.p_name, 
           sd.s_name, 
           sd.nation_name, 
           sd.region_name, 
           ls.total_quantity, 
           ls.average_price, 
           ls.max_discount
    FROM PartDetails pd
    JOIN partsupp ps ON pd.p_partkey = ps.ps_partkey
    JOIN SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
    JOIN LineItemSummary ls ON pd.p_partkey = ls.l_partkey
)
SELECT * 
FROM CombinedData 
WHERE average_price < (SELECT AVG(average_price) FROM LineItemSummary)
ORDER BY total_quantity DESC, average_price ASC;
