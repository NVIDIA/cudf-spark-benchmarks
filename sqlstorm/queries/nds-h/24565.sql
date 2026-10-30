
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        CASE 
            WHEN p.p_size IS NULL THEN 'N/A' 
            WHEN p.p_retailprice < 100 THEN 'Cheap' 
            WHEN p.p_retailprice BETWEEN 100 AND 500 THEN 'Moderate' 
            ELSE 'Expensive' 
        END AS price_category
    FROM 
        part p
    WHERE 
        p.p_comment LIKE '%fragile%'
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_linenumber) AS line_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
QualifiedOrders AS (
    SELECT 
        od.o_orderkey,
        od.line_count,
        od.total_price,
        CASE 
            WHEN od.total_price > 1000 THEN 'Large Order' 
            ELSE 'Small Order' 
        END AS order_size
    FROM 
        OrderDetails od
    WHERE 
        EXISTS (
            SELECT 1
            FROM FilteredParts fp
            WHERE fp.p_partkey IN (
                SELECT ps.ps_partkey
                FROM partsupp ps
                WHERE ps.ps_supplycost < 50
            )
            AND fp.p_retailprice <= od.total_price
        )
)
SELECT 
    c.c_name AS customer_name,
    c.c_address AS customer_address,
    o.order_size,
    rs.s_name AS supplier,
    rp.price_category 
FROM 
    customer c
JOIN 
    QualifiedOrders o ON c.c_custkey = o.o_orderkey
LEFT JOIN 
    RankedSuppliers rs ON c.c_nationkey = rs.s_nationkey AND rs.rn = 1
LEFT JOIN 
    FilteredParts rp ON rp.p_partkey = (
        SELECT fp.p_partkey
        FROM FilteredParts fp
        ORDER BY fp.p_retailprice DESC
        LIMIT 1
    )
WHERE 
    c.c_acctbal IS NOT NULL
    AND o.line_count > 0
    AND o.order_size = 'Large Order'
UNION 
SELECT 
    NULL AS customer_name,
    NULL AS customer_address,
    o.order_size,
    rs.s_name AS supplier,
    NULL AS price_category 
FROM 
    QualifiedOrders o
CROSS JOIN 
    RankedSuppliers rs
WHERE 
    rs.rn <= 2
    AND o.line_count = 0
ORDER BY 
    customer_name ASC NULLS LAST, 
    supplier ASC;
