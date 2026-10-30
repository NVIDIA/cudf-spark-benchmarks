WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
        AND o.o_orderstatus IN ('O', 'F')
),
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 0
)
SELECT 
    r.o_orderkey,
    r.o_orderstatus,
    r.o_totalprice,
    r.o_orderdate,
    spd.s_name AS supplier_name,
    spd.p_name AS part_name,
    spd.ps_availqty,
    COALESCE(spd.ps_supplycost, 0) AS supply_cost,
    CASE 
        WHEN r.o_totalprice > 1000 THEN 'High Value'
        WHEN r.o_totalprice BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS price_category,
    COUNT(spd.s_suppkey) OVER (PARTITION BY r.o_orderkey) AS supplier_count
FROM 
    RankedOrders r
LEFT JOIN 
    SupplierPartDetails spd ON r.o_orderkey = spd.p_partkey
WHERE 
    r.o_orderstatus = 'O'
    AND rnk <= 10
ORDER BY 
    r.o_orderdate DESC,
    r.o_totalprice DESC;