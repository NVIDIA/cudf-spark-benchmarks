WITH FilteredSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_comment
    FROM supplier s
    WHERE s.s_acctbal > 5000.00
),
PartSupplierCounts AS (
    SELECT ps.ps_partkey, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    JOIN FilteredSuppliers fs ON ps.ps_suppkey = fs.s_suppkey
    GROUP BY ps.ps_partkey
),
HighDemandParts AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, 
           p.p_container, p.p_retailprice, p.p_comment, 
           psc.supplier_count
    FROM part p
    JOIN PartSupplierCounts psc ON p.p_partkey = psc.ps_partkey
    WHERE psc.supplier_count > 10 AND p.p_size BETWEEN 1 AND 10
)
SELECT hd.p_partkey, hd.p_name, hd.p_mfgr, hd.p_brand, hd.p_type, 
       hd.p_retailprice, hd.supplier_count, n.n_name AS supplier_nation
FROM HighDemandParts hd
JOIN partsupp ps ON hd.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
WHERE hd.p_retailprice < (SELECT AVG(p2.p_retailprice) FROM part p2)
ORDER BY hd.supplier_count DESC, hd.p_retailprice ASC;
