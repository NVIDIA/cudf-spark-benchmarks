WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        LENGTH(p.p_comment) AS comment_length,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY LENGTH(p.p_comment) DESC) AS brand_rank
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 10 AND 20
),
TopComments AS (
    SELECT 
        rp.p_partkey, 
        rp.p_name,
        rp.comment_length
    FROM 
        RankedParts rp
    WHERE 
        rp.brand_rank <= 5
),
SupplierComments AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(LENGTH(ps.ps_comment)) AS total_comment_length
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
FinalBenchmark AS (
    SELECT 
        tc.p_partkey,
        tc.p_name,
        sc.s_name,
        tc.comment_length,
        sc.total_comment_length
    FROM 
        TopComments tc
    JOIN 
        SupplierComments sc ON tc.p_partkey IN (
            SELECT ps.ps_partkey 
            FROM partsupp ps 
            WHERE ps.ps_supplycost < 50
        )
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    EXISTS (
        SELECT 1 
        FROM FinalBenchmark fb 
        WHERE fb.p_partkey = p.p_partkey
    )
GROUP BY 
    p.p_partkey, p.p_name
ORDER BY 
    total_revenue DESC;
