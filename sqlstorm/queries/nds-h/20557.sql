WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_retailprice, 
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p 
    WHERE 
        p.p_retailprice IS NOT NULL
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        COUNT(ps.ps_availqty) AS available_parts
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
), 
FilteredOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        c.c_name
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
), 
HighValueShipments AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        lineitem l
    JOIN 
        FilteredOrders fo ON l.l_orderkey = fo.o_orderkey
    GROUP BY 
        l.l_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
), 
FinalReport AS (
    SELECT 
        rp.p_name,
        sd.s_name,
        sd.nation_name,
        hvs.total_value,
        (SELECT COUNT(*) FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM FilteredOrders o)) AS total_line_items
    FROM 
        RankedParts rp
    JOIN 
        SupplierDetails sd ON sd.available_parts > 0
    LEFT JOIN 
        HighValueShipments hvs ON hvs.l_orderkey = rp.p_partkey
    WHERE 
        rp.price_rank <= 5 
        AND sd.nation_name IS NOT NULL
)
SELECT 
    freport.*, 
    CASE 
        WHEN freport.total_value IS NULL THEN 'No High Value Shipment' 
        ELSE CAST(freport.total_value AS STRING)
    END AS shipment_status
FROM 
    FinalReport freport
ORDER BY 
    freport.total_value DESC NULLS LAST, freport.p_name;
