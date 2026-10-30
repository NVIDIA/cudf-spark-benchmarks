WITH SupplierDetails AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_address,
           n.n_name AS nation_name,
           r.r_name AS region_name,
           LENGTH(s.s_comment) AS comment_length
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
PartDetails AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_mfgr, 
           p.p_brand, 
           p.p_type, 
           p.p_size,
           LENGTH(p.p_comment) AS comment_length
    FROM part p
),
LineItemSummary AS (
    SELECT l.l_partkey,
           SUM(l.l_quantity) AS total_quantity,
           AVG(l.l_extendedprice) AS avg_extended_price,
           COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM lineitem l 
    GROUP BY l.l_partkey
)
SELECT sd.s_suppkey, 
       sd.s_name,
       pd.p_partkey,
       pd.p_name,
       pd.p_type,
       SUM(lis.total_quantity) AS total_quantity_sold,
       AVG(lis.avg_extended_price) AS average_price,
       sd.comment_length AS supplier_comment_length,
       pd.comment_length AS part_comment_length
FROM SupplierDetails sd
JOIN partsupp ps ON sd.s_suppkey = ps.ps_suppkey
JOIN PartDetails pd ON ps.ps_partkey = pd.p_partkey
JOIN LineItemSummary lis ON pd.p_partkey = lis.l_partkey
GROUP BY sd.s_suppkey, 
         sd.s_name, 
         pd.p_partkey, 
         pd.p_name, 
         pd.p_type, 
         sd.comment_length, 
         pd.comment_length
ORDER BY total_quantity_sold DESC, average_price DESC;
