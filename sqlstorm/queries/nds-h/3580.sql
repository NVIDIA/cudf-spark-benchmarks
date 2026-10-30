
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS supplier_nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
OrderLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(*) AS total_items
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    COALESCE(ol.total_price, 0) AS total_lineitem_price,
    si.supplier_nation,
    si.total_supply_cost,
    CASE 
        WHEN ro.o_orderstatus = 'F' THEN 'Finished'
        WHEN ro.o_orderstatus = 'P' THEN 'Pending'
        ELSE 'Other'
    END AS order_status_description
FROM 
    RankedOrders ro
LEFT JOIN 
    OrderLineItems ol ON ro.o_orderkey = ol.l_orderkey
LEFT JOIN 
    SupplierInfo si ON si.total_supply_cost > 10000
WHERE 
    ro.rn = 1 AND 
    (ro.o_orderstatus IS NOT NULL OR ro.o_totalprice IS NOT NULL)
ORDER BY 
    ro.o_orderdate DESC, 
    ro.o_totalprice DESC;
