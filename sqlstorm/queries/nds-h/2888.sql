WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders AS o
    WHERE 
        o.o_orderstatus = 'O' 
        AND o.o_orderdate >= '1997-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_value
    FROM 
        supplier AS s
    JOIN 
        partsupp AS ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueSuppliers AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name
    FROM 
        SupplierDetails AS sd
    WHERE 
        sd.total_supply_value > (
            SELECT AVG(total_supply_value) FROM SupplierDetails
        )
),
RecentOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice
    FROM 
        RankedOrders AS ro
    WHERE 
        ro.rn = 1
)
SELECT 
    coalesce(hvs.s_name, 'Unknown Supplier') AS supplier_name,
    SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue,
    COUNT(DISTINCT ro.o_orderkey) AS number_of_orders
FROM 
    lineitem AS lo
LEFT JOIN 
    RecentOrders AS ro ON lo.l_orderkey = ro.o_orderkey
LEFT JOIN 
    partsupp AS ps ON lo.l_partkey = ps.ps_partkey 
LEFT JOIN 
    HighValueSuppliers AS hvs ON ps.ps_suppkey = hvs.s_suppkey
WHERE 
    lo.l_shipdate > cast('1998-10-01' as date) - interval '30 days'
    AND (lo.l_returnflag = 'R' OR lo.l_linestatus = 'F')
GROUP BY 
    hvs.s_name
ORDER BY 
    total_revenue DESC
LIMIT 10;