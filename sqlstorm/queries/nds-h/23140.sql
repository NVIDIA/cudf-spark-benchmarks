
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        o.o_orderkey,
        COUNT(*) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, o.o_orderkey
),
CombinedData AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        COALESCE(sa.total_avail_qty, 0) AS total_avail_qty,
        COALESCE(co.order_count, 0) AS customer_order_count,
        rp.p_retailprice
    FROM 
        RankedParts rp
    LEFT JOIN 
        SupplierAvailability sa ON rp.p_partkey = sa.ps_partkey
    LEFT JOIN 
        CustomerOrders co ON co.c_custkey = (SELECT MIN(c.c_custkey) FROM customer c WHERE c.c_acctbal > 1000)
    WHERE 
        rp.rn <= 10 AND 
        (rp.p_retailprice - COALESCE(sa.total_avail_qty, 0) * 0.1) > 0
)
SELECT 
    cb.p_partkey,
    cb.p_name,
    cb.total_avail_qty,
    cb.customer_order_count,
    CASE 
        WHEN cb.customer_order_count > 0 THEN 
            'Active Customer'
        ELSE 
            'Inactive Customer'
    END AS customer_status,
    (cb.p_retailprice - (cb.total_avail_qty * (SELECT AVG(ps_supplycost) FROM partsupp WHERE ps_partkey = cb.p_partkey))) AS effective_price
FROM 
    CombinedData cb
WHERE 
    cb.total_avail_qty IS NOT NULL
ORDER BY 
    effective_price ASC, cb.customer_order_count DESC;
