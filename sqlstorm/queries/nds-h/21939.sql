WITH RankedSuppliers AS (
    SELECT 
        s_suppkey, 
        s_name, 
        s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) AS rnk
    FROM 
        supplier
),
AvailableParts AS (
    SELECT 
        ps_partkey, 
        SUM(ps_availqty) AS total_availqty,
        AVG(ps_supplycost) AS avg_supplycost
    FROM 
        partsupp
    GROUP BY 
        ps_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_brand, 
    p.p_retailprice, 
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    ca.total_order_value,
    rp.total_availqty,
    rp.avg_supplycost
FROM 
    part p
LEFT JOIN 
    AvailableParts rp ON p.p_partkey = rp.ps_partkey
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey AND s.rnk = 1
LEFT JOIN 
    CustomerOrders ca ON ca.o_orderkey = ps.ps_partkey
WHERE 
    (p.p_size >= 10 OR p.p_size IS NULL)
    AND (p.p_comment LIKE '%special%' OR rp.total_availqty > 100)
ORDER BY 
    p.p_retailprice DESC, 
    total_order_value NULLS LAST
LIMIT 100;