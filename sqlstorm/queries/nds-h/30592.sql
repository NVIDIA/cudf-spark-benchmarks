WITH  CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
), 
HighValueOrders AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.o_orderkey,
        co.o_orderdate,
        co.o_totalprice
    FROM 
        CustomerOrders co
    WHERE 
        co.order_rank = 1 AND co.o_totalprice > 1000
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    hvo.c_name,
    hvo.o_orderkey,
    hvo.o_orderdate,
    hvo.o_totalprice,
    pp.p_name,
    sp.total_avail_qty,
    sp.avg_supply_cost,
    CASE 
        WHEN sp.total_avail_qty IS NULL THEN 'No Supplier'
        ELSE 'Available'
    END AS supplier_status
FROM 
    HighValueOrders hvo
LEFT JOIN 
    lineitem li ON hvo.o_orderkey = li.l_orderkey
LEFT JOIN 
    part pp ON li.l_partkey = pp.p_partkey
LEFT JOIN 
    SupplierParts sp ON pp.p_partkey = sp.ps_partkey
WHERE 
    hvo.o_orderdate >= '1997-01-01' 
    AND (sp.total_avail_qty > 100 OR sp.total_avail_qty IS NULL)
ORDER BY 
    hvo.o_totalprice DESC, 
    hvo.o_orderdate ASC;