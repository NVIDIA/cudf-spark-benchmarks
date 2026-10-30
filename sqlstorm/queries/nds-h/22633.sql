WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        RANK() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_size BETWEEN 5 AND 10
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'BALANCE UNKNOWN' 
            ELSE CASE 
                WHEN s.s_acctbal < 1000 THEN 'LOW BALANCE'
                WHEN s.s_acctbal BETWEEN 1000 AND 5000 THEN 'MEDIUM BALANCE'
                ELSE 'HIGH BALANCE'
            END 
        END AS balance_status
    FROM supplier s 
    WHERE s.s_comment IS NOT NULL
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_value,
        COUNT(DISTINCT l.l_linenumber) AS item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate > '1996-01-01' 
    GROUP BY o.o_orderkey
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_retailprice,
    si.s_name,
    si.balance_status,
    od.net_value,
    od.item_count
FROM RankedParts rp 
LEFT JOIN partsupp ps ON rp.p_partkey = ps.ps_partkey
LEFT JOIN SupplierInfo si ON ps.ps_suppkey = si.s_suppkey
JOIN OrderDetails od ON rp.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O'))
WHERE rp.price_rank = 1
AND si.s_acctbal IS NOT NULL
ORDER BY rp.p_retailprice DESC, od.net_value ASC
LIMIT 50;