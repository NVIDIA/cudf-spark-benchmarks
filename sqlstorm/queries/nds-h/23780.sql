WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
), 
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 50000
),
RelevantParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL AND p.p_size >= 10
), 
MixAndMatch AS (
    SELECT 
        ro.o_orderkey,
        rp.p_name,
        rp.p_brand,
        l.l_quantity,
        l.l_extendedprice,
        CASE 
            WHEN l.l_discount = 0 THEN NULL 
            ELSE l.l_extendedprice * (1 - l.l_discount) * 0.1
        END AS discount_value
    FROM 
        RankedOrders ro 
    JOIN 
        lineitem l ON ro.o_orderkey = l.l_orderkey
    JOIN 
        RelevantParts rp ON l.l_partkey = rp.p_partkey
    WHERE 
        ro.price_rank <= 5
)
SELECT 
    mm.o_orderkey,
    COUNT(DISTINCT mm.p_name) AS unique_parts_ordered,
    SUM(mm.l_extendedprice) AS total_extended_price,
    SUM(mm.discount_value) AS total_discount_value,
    (SELECT COUNT(DISTINCT hs.s_suppkey)
     FROM HighValueSuppliers hs 
     WHERE hs.total_supply_value > (SELECT AVG(total_supply_value) FROM HighValueSuppliers)) AS high_value_supplier_count
FROM 
    MixAndMatch mm
GROUP BY 
    mm.o_orderkey
HAVING 
    SUM(mm.l_quantity) > (
        SELECT AVG(l_quantity)
        FROM lineitem 
        WHERE l_returnflag = 'N'
    ) AND SUM(mm.l_extendedprice) IS NOT NULL
ORDER BY 
    mm.o_orderkey;
