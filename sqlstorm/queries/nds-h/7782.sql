WITH SupplyDetails AS (
    SELECT 
        p.p_name,
        s.s_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        (l.l_extendedprice * (1 - l.l_discount)) AS discounted_price,
        o.o_orderdate,
        o.o_orderstatus
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        l.l_shipdate >= '1997-01-01' AND 
        o.o_orderstatus = 'F' 
),
RankedSupplies AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY p_name ORDER BY discounted_price DESC) AS rnk
    FROM 
        SupplyDetails
)
SELECT 
    rnk,
    p_name,
    s_name,
    ps_supplycost,
    ps_availqty,
    l_quantity,
    discounted_price,
    o_orderdate
FROM 
    RankedSupplies
WHERE 
    rnk <= 3
ORDER BY 
    p_name, discounted_price DESC;