WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) as rn
    FROM part p
    WHERE p.p_size > (SELECT AVG(p2.p_size) FROM part p2)
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 0
    GROUP BY c.c_custkey
),
TotalSales AS (
    SELECT 
        l.l_partkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    WHERE l.l_shipmode IN ('AIR', 'SEA')
    GROUP BY l.l_partkey
)
SELECT 
    rp.p_partkey, 
    rp.p_name, 
    rp.p_retailprice,
    COALESCE(sd.total_supply_cost, 0) AS total_supply_cost,
    COALESCE(co.order_count, 0) AS order_count,
    ts.total_sales
FROM RankedParts rp
LEFT JOIN SupplierDetails sd ON rp.p_partkey = sd.s_suppkey  
LEFT JOIN CustomerOrders co ON rp.p_partkey = co.c_custkey  
LEFT JOIN TotalSales ts ON rp.p_partkey = ts.l_partkey
WHERE 
    (rp.rn <= 5 OR ts.total_sales IS NULL)
    AND rp.p_retailprice > (SELECT AVG(p3.p_retailprice) FROM part p3 WHERE p3.p_container IS NOT NULL)
ORDER BY 
    rp.p_retailprice DESC, 
    total_supply_cost DESC;