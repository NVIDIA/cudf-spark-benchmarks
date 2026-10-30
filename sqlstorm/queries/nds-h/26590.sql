
WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, n.n_name AS nation_name,
           TRIM(s.s_comment) AS trimmed_comment,
           LENGTH(TRIM(s.s_comment)) AS comment_length
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE LENGTH(TRIM(s.s_comment)) > 50 AND s.s_acctbal > 1000
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand,
           UPPER(p.p_brand) AS upper_brand,
           LOWER(p.p_name) AS lower_name,
           CHAR_LENGTH(p.p_comment) AS comment_size
    FROM part p
    WHERE p.p_retailprice BETWEEN 10.00 AND 100.00
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderstatus,
           CONCAT(o.o_clerk, ': ', o.o_comment) AS detailed_comment,
           SUBSTRING(o.o_orderpriority, 1, 3) AS short_priority
    FROM orders o
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate <= '1997-12-31'
)
SELECT sd.s_name, pd.p_name, od.o_orderkey,
       CONCAT(sd.nation_name, ' - ', sd.trimmed_comment) AS full_supplier_info,
       CONCAT(pd.upper_brand, ' / ', pd.lower_name) AS formatted_part_info,
       od.detailed_comment, od.short_priority
FROM SupplierDetails sd
JOIN PartDetails pd ON sd.s_suppkey = pd.p_partkey
JOIN OrderDetails od ON od.o_orderkey = pd.p_partkey
WHERE sd.comment_length > 70 AND pd.comment_size < 30
ORDER BY sd.nation_name, pd.p_name;
