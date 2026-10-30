WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
),
SupplierAvg AS (
    SELECT 
        ps.ps_partkey,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    rp.p_name,
    rp.p_retailprice,
    sa.avg_supply_cost,
    co.c_name,
    co.order_count,
    co.total_spent
FROM 
    RankedParts rp
JOIN 
    SupplierAvg sa ON rp.p_partkey = sa.ps_partkey
LEFT JOIN 
    CustomerOrders co ON co.total_spent > (SELECT COALESCE(AVG(total_spent), 0) FROM CustomerOrders) 
WHERE 
    rp.price_rank = 1 
    OR (rp.p_retailprice < 100 AND sa.avg_supply_cost IS NOT NULL)
ORDER BY 
    rp.p_retailprice DESC, co.total_spent ASC 
    NULLS LAST
LIMIT 10;

