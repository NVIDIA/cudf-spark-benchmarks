WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_container,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_size >= 24
),
PreferredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        COUNT(ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
    HAVING 
        COUNT(ps.ps_partkey) > 5
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS unique_items
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_container,
    ps.s_name,
    os.total_revenue,
    os.unique_items
FROM 
    RankedParts rp
JOIN 
    PreferredSuppliers ps ON rp.p_partkey = ps.s_nationkey
JOIN 
    OrderStats os ON ps.s_nationkey = os.o_orderkey
WHERE 
    rp.rn <= 5 
ORDER BY 
    os.total_revenue DESC, rp.p_brand, rp.p_name;