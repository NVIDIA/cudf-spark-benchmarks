WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS TotalAvailableQty,
        COUNT(DISTINCT ps.ps_partkey) AS TotalPartsSupplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > 0
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        CASE 
            WHEN l.l_discount > 0.2 THEN 'High' 
            ELSE 'Regular' 
        END AS DiscountCategory
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1996-01-01'
),
OrderSupplierDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        s.s_name AS SupplierName,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax
    FROM 
        RankedOrders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    LEFT JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        o.OrderRank <= 10 AND 
        (l.l_discount IS NOT NULL OR l.l_tax IS NOT NULL)
)
SELECT 
    ods.o_orderkey,
    ods.o_totalprice,
    ods.SupplierName,
    SUM(ods.l_extendedprice * (1 - ods.l_discount)) AS AdjustedPrice,
    COUNT(DISTINCT s.TotalPartsSupplied) AS DistinctSuppliers,
    HVL.DiscountCategory
FROM 
    OrderSupplierDetails ods
LEFT JOIN 
    SupplierStats s ON ods.SupplierName = s.s_name
JOIN 
    HighValueLineItems HVL ON ods.o_orderkey = HVL.l_orderkey
GROUP BY 
    ods.o_orderkey, ods.o_totalprice, ods.SupplierName, HVL.DiscountCategory
HAVING 
    SUM(ods.l_extendedprice * (1 - ods.l_discount)) > 1000 
ORDER BY 
    AdjustedPrice DESC;