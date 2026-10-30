WITH RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, ps.ps_availqty, 
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS PartRank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
TopParts AS (
    SELECT r.r_name, np.n_name, rp.p_name, rp.p_retailprice, rp.ps_availqty
    FROM RankedParts rp
    JOIN supplier s ON rp.p_partkey = s.s_suppkey
    JOIN nation np ON s.s_nationkey = np.n_nationkey
    JOIN region r ON np.n_regionkey = r.r_regionkey
    WHERE rp.PartRank <= 5
)
SELECT r_name, n_name, COUNT(*) AS PartCount, 
       SUM(p_retailprice) AS TotalRetailPrice, 
       AVG(ps_availqty) AS AverageAvailableQuantity
FROM TopParts
GROUP BY r_name, n_name
ORDER BY r_name, TotalRetailPrice DESC;
