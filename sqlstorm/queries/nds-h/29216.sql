WITH FilteredParts AS (
    SELECT p_partkey, 
           p_name, 
           p_retailprice, 
           p_size, 
           p_comment,
           LENGTH(p_comment) AS comment_length,
           UPPER(p_name) AS upper_name
    FROM part
    WHERE p_retailprice > 100.00
      AND p_size BETWEEN 10 AND 50
), 
SupplierDetails AS (
    SELECT s_suppkey, 
           s_name, 
           s_acctbal,
           s_comment,
           LENGTH(s_comment) AS supplier_comment_length
    FROM supplier
    WHERE s_acctbal > 5000.00
), 
OrderDetails AS (
    SELECT o_orderkey, 
           o_custkey, 
           o_totalprice, 
           o_orderdate,
           o_orderstatus,
           EXTRACT(YEAR FROM o_orderdate) AS order_year
    FROM orders
    WHERE o_orderstatus = 'O'
), 
CombiningData AS (
    SELECT fp.p_partkey, 
           fp.upper_name, 
           fp.p_retailprice, 
           fp.p_comment,
           fp.comment_length, 
           sd.s_name AS supplier_name,
           sd.s_acctbal AS supplier_balance,
           sd.supplier_comment_length,
           od.o_orderkey,
           od.o_totalprice,
           od.order_year
    FROM FilteredParts fp
    JOIN partsupp ps ON fp.p_partkey = ps.ps_partkey
    JOIN SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
    JOIN lineitem li ON ps.ps_partkey = li.l_partkey
    JOIN OrderDetails od ON li.l_orderkey = od.o_orderkey
)
SELECT upper_name, 
       p_retailprice, 
       comment_length, 
       supplier_name, 
       supplier_balance, 
       supplier_comment_length, 
       COUNT(o_orderkey) AS order_count, 
       SUM(o_totalprice) AS total_order_value
FROM CombiningData
GROUP BY upper_name, 
         p_retailprice, 
         comment_length,
         supplier_name, 
         supplier_balance, 
         supplier_comment_length
ORDER BY total_order_value DESC, 
         order_count DESC;
