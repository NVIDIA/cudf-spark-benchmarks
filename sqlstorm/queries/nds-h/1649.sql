WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_retailprice,
    COALESCE(sa.total_available, 0) AS total_available,
    co.total_order_value,
    CASE 
        WHEN co.total_order_value IS NULL THEN 'No orders' 
        ELSE 'Ordered'
    END AS order_status
FROM RankedParts rp
LEFT JOIN SupplierAvailability sa ON rp.p_partkey = sa.ps_partkey
LEFT JOIN CustomerOrders co ON co.o_custkey = (SELECT c.c_custkey 
                                               FROM customer c 
                                               WHERE c.c_nationkey = (SELECT n.n_nationkey 
                                                                      FROM nation n 
                                                                      JOIN region r ON n.n_regionkey = r.r_regionkey 
                                                                      WHERE r.r_name = 'Europe' LIMIT 1))
WHERE rp.rn <= 5
ORDER BY rp.p_retailprice DESC, total_available DESC;
