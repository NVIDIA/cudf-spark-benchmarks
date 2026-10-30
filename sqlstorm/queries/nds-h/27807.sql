
WITH PartSupplier AS (
    SELECT p.p_partkey, 
           p.p_name, 
           s.s_name AS supplier_name, 
           CONCAT(s.s_address, ', ', n.n_name, ', ', r.r_name) AS full_address, 
           s.s_acctbal, 
           s.s_comment, 
           p.p_retailprice 
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
), 
ProcessedComments AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.supplier_name, 
           p.full_address, 
           p.s_acctbal, 
           LENGTH(p.s_comment) AS comment_length,
           UPPER(p.s_comment) AS upper_comment 
    FROM PartSupplier p
) 
SELECT p_name, 
       supplier_name, 
       full_address, 
       s_acctbal, 
       comment_length, 
       upper_comment 
FROM ProcessedComments 
WHERE comment_length > 50 
ORDER BY comment_length DESC, 
         p_name ASC
LIMIT 10;
