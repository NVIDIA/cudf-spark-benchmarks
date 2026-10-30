
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_size ORDER BY p.p_retailprice DESC) AS price_rnk
    FROM part p
    WHERE p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 50)
),
SupplierWithQualifyingParts AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied,
        SUM(CASE WHEN rp.price_rnk = 1 THEN rp.p_retailprice ELSE 0 END) AS highest_price_supply
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN RankedParts rp ON ps.ps_partkey = rp.p_partkey
    GROUP BY s.s_suppkey
    HAVING SUM(ps.ps_availqty) > 100 AND COUNT(DISTINCT ps.ps_partkey) > 5
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value,
        COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING AVG(o.o_totalprice) IS NOT NULL
),
FinalResults AS (
    SELECT 
        cu.c_name,
        cu.total_spent,
        COALESCE(s.parts_supplied, 0) AS total_parts_supplied,
        COALESCE(s.highest_price_supply, 0) AS highest_price_supply
    FROM CustomerSummary cu
    LEFT JOIN SupplierWithQualifyingParts s ON s.parts_supplied > 0
    ORDER BY cu.total_spent DESC
)
SELECT 
    f.c_name,
    f.total_spent,
    f.total_parts_supplied,
    f.highest_price_supply,
    CASE 
        WHEN f.total_spent > 5000 THEN 'VIP' 
        WHEN f.total_spent IS NULL THEN 'NULL_SPENDER' 
        ELSE 'REGULAR' 
    END AS customer_status
FROM FinalResults f
WHERE f.total_parts_supplied > (
    SELECT AVG(parts_supplied) FROM SupplierWithQualifyingParts
)
OR f.highest_price_supply > (
    SELECT MAX(highest_price_supply) * 0.8 FROM SupplierWithQualifyingParts
)
ORDER BY f.total_spent DESC, f.c_name ASC
LIMIT 10;
