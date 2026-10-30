WITH RankedParts AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_quantity) AS total_quantity, AVG(s.s_acctbal) AS avg_supplier_balance
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN lineitem l ON l.l_partkey = p.p_partkey
    GROUP BY p.p_partkey, p.p_name
), FilteredParts AS (
    SELECT p.*, RANK() OVER (ORDER BY total_quantity DESC) AS rank_quantity
    FROM RankedParts p
    WHERE avg_supplier_balance > 1000
)
SELECT fp.p_partkey, fp.p_name, fp.total_quantity
FROM FilteredParts fp
WHERE fp.rank_quantity <= 10
ORDER BY fp.total_quantity DESC;
