WITH  CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus IN ('O', 'F')
    GROUP BY 
        c.c_custkey, c.c_name
), SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), MinMaxShipping AS (
    SELECT 
        l.l_shipmode,
        MIN(l.l_shipdate) AS min_shipdate,
        MAX(l.l_shipdate) AS max_shipdate,
        COUNT(*) AS total_shipments
    FROM 
        lineitem l
    WHERE 
        l.l_discount > 0.1
    GROUP BY 
        l.l_shipmode
)
SELECT 
    co.c_custkey,
    co.c_name,
    COALESCE(co.total_spent, 0) AS total_spent,
    sp.parts_supplied,
    CASE 
        WHEN sp.parts_supplied IS NULL THEN 'No parts supplied'
        ELSE 'Parts supplied: ' || sp.parts_supplied
    END AS parts_supply_info,
    mms.l_shipmode,
    mms.min_shipdate,
    mms.max_shipdate,
    mms.total_shipments,
    ROW_NUMBER() OVER (PARTITION BY co.c_custkey ORDER BY co.total_spent DESC) AS customer_rank
FROM 
    CustomerOrders co
FULL OUTER JOIN 
    SupplierParts sp ON co.c_custkey = sp.s_suppkey
LEFT JOIN 
    MinMaxShipping mms ON mms.l_shipmode = 'TRUCK'
WHERE 
    (sp.parts_supplied IS NOT NULL OR co.total_spent > 100)
    AND NOT EXISTS (
        SELECT 1 
        FROM orders o 
        WHERE o.o_custkey = co.c_custkey 
        AND o.o_orderstatus = 'C'
    )
ORDER BY 
    co.c_name ASC NULLS LAST, 
    total_spent DESC;
