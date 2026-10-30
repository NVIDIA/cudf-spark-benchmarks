SELECT COUNT(*) AS total_parts, AVG(p_retailprice) AS average_price
FROM part
WHERE p_size > 10;
