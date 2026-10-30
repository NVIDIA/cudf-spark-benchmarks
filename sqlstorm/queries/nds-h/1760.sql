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
        o.o_orderdate >= '1997-01-01' 
        AND o.o_orderstatus IN ('O', 'F')
), SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COALESCE(SUM(ps.ps_supplycost * ps.ps_availqty), 0) AS total_supply_value
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
), PartInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
), OrdersWithLineItems AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        o.o_orderstatus,
        COUNT(l.l_orderkey) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
)
SELECT 
    rn,
    R.o_orderkey,
    R.o_orderdate,
    R.o_totalprice,
    R.o_orderstatus,
    COALESCE(SD.total_supply_value, 0) AS supplier_total_value,
    P.p_name,
    P.p_brand,
    P.supplier_count,
    O.total_revenue,
    O.line_item_count
FROM 
    RankedOrders R
LEFT JOIN 
    SupplierDetails SD ON R.o_orderkey = SD.s_suppkey
LEFT JOIN 
    PartInfo P ON R.o_orderkey = P.p_partkey
LEFT JOIN 
    OrdersWithLineItems O ON R.o_orderkey = O.o_orderkey
WHERE 
    (P.supplier_count > 2 OR O.line_item_count > 5)
ORDER BY 
    R.o_orderdate DESC NULLS LAST
LIMIT 50 OFFSET 0;