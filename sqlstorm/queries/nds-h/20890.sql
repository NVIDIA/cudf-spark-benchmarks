WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 1000
), SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
), RecentLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        RANK() OVER (ORDER BY l.l_shipdate DESC) AS shipment_rank
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= cast('1998-10-01' as date) - INTERVAL '30 DAY'
), DefaultRegion AS (
    SELECT 
        r.r_regionkey,
        r.r_name
    FROM 
        region r
    WHERE 
        r.r_name = 'DEFAULT'
)
SELECT 
    co.c_custkey,
    co.c_name,
    ro.o_orderkey,
    ro.o_orderstatus,
    ro.o_totalprice,
    rli.l_orderkey,
    rli.l_quantity,
    s.s_suppkey,
    s.parts_supplied,
    s.total_cost,
    CASE 
        WHEN s.total_cost IS NULL THEN 'No Supplies'
        ELSE 'Supplied'
    END AS supply_status,
    COALESCE(d.r_name, 'Unknown Region') AS region_name
FROM 
    CustomerOrders co
JOIN 
    RankedOrders ro ON ro.o_orderkey = co.c_custkey
JOIN 
    RecentLineItems rli ON rli.l_orderkey = ro.o_orderkey
LEFT JOIN 
    SupplierStats s ON s.parts_supplied > 10 AND s.total_cost < 5000
LEFT JOIN 
    DefaultRegion d ON s.parts_supplied IS NULL 
WHERE 
    (ro.order_rank = 1 OR ro.o_orderstatus = 'F')
    AND co.total_spent IS NOT NULL
ORDER BY 
    co.total_spent DESC, ro.o_totalprice DESC
LIMIT 100;