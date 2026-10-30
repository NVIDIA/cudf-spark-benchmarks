WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        CASE 
            WHEN LENGTH(s.s_comment) > 50 THEN SUBSTR(s.s_comment, 1, 50) || '...' 
            ELSE s.s_comment 
        END AS short_comment
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 5000
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    fp.p_name,
    fp.p_brand,
    fs.s_name,
    cs.c_name,
    cs.total_orders,
    cs.total_spent,
    cs.avg_order_value
FROM 
    RankedParts fp
JOIN 
    partsupp ps ON fp.p_partkey = ps.ps_partkey
JOIN 
    FilteredSuppliers fs ON ps.ps_suppkey = fs.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    CustomerOrderStats cs ON o.o_custkey = cs.c_custkey
WHERE 
    fp.rn <= 5 AND 
    fs.short_comment LIKE '%important%' AND 
    cs.total_spent > 10000
ORDER BY 
    fp.p_retailprice DESC, cs.total_spent DESC;
