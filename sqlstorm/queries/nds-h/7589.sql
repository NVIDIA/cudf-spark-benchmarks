WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
), 
SupplierPart AS (
    SELECT 
        sp.ps_partkey,
        s.s_name,
        s.s_acctbal,
        sp.ps_supplycost
    FROM partsupp sp
    JOIN supplier s ON sp.ps_suppkey = s.s_suppkey
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
)
SELECT 
    rp.p_name,
    rp.p_brand,
    sp.s_name AS supplier_name,
    sp.s_acctbal AS supplier_account_balance,
    co.c_name AS customer_name,
    co.total_spent
FROM RankedParts rp
JOIN SupplierPart sp ON rp.p_partkey = sp.ps_partkey
JOIN CustomerOrders co ON sp.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
WHERE rp.price_rank <= 5
ORDER BY co.total_spent DESC, rp.p_retailprice DESC
LIMIT 10;
