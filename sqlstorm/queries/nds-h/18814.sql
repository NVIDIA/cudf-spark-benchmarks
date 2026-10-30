SELECT s_name, s_acctbal 
FROM supplier 
WHERE s_acctbal > 1000 
ORDER BY s_acctbal DESC 
LIMIT 10;
