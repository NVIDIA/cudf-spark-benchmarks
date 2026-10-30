
WITH FilteredParts AS (
    SELECT p_partkey, 
           p_name, 
           p_brand, 
           p_size, 
           p_retailprice, 
           p_comment,
           LENGTH(p_comment) AS comment_length
    FROM part
    WHERE p_brand LIKE 'Brand%'
      AND p_size > 20
), TotalSuppliers AS (
    SELECT ps_partkey, 
           COUNT(DISTINCT ps_suppkey) AS supplier_count
    FROM partsupp
    GROUP BY ps_partkey
), TopCustomers AS (
    SELECT c_custkey, 
           c_name, 
           SUM(o_totalprice) AS total_spent
    FROM customer
    JOIN orders ON c_custkey = o_custkey
    GROUP BY c_custkey, c_name
    ORDER BY total_spent DESC
    LIMIT 10
)
SELECT fp.p_partkey,
       fp.p_name,
       fp.p_brand,
       fp.p_size,
       fp.p_retailprice,
       fp.comment_length,
       tc.total_spent,
       tc.c_name
FROM FilteredParts fp
JOIN TotalSuppliers ts ON fp.p_partkey = ts.ps_partkey
JOIN TopCustomers tc ON ts.supplier_count > 5
WHERE tc.total_spent > 5000.00
ORDER BY fp.p_retailprice DESC, tc.total_spent DESC;
