
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
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate <= DATE '1997-09-30'
),
HighValueLineitems AS (
    SELECT 
        li.l_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_value
    FROM 
        lineitem li
    JOIN 
        RankedOrders ro ON li.l_orderkey = ro.o_orderkey
    WHERE 
        li.l_shipdate >= DATE '1996-01-01'
    GROUP BY 
        li.l_orderkey
    HAVING 
        SUM(li.l_extendedprice * (1 - li.l_discount)) > (SELECT AVG(total_value) FROM (SELECT SUM(l_extendedprice * (1 - l_discount)) AS total_value FROM lineitem GROUP BY l_orderkey) AS avg_values)
),
SupplierInfo AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        s.s_name
    HAVING 
        SUM(ps.ps_availqty) > 100
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    hl.total_value AS lineitem_value,
    si.s_name,
    si.total_available
FROM 
    RankedOrders ro
JOIN 
    HighValueLineitems hl ON ro.o_orderkey = hl.l_orderkey
JOIN 
    lineitem li ON hl.l_orderkey = li.l_orderkey
JOIN 
    SupplierInfo si ON li.l_partkey = si.ps_partkey AND li.l_suppkey = si.ps_suppkey
ORDER BY 
    ro.o_orderdate DESC, hl.total_value DESC;
