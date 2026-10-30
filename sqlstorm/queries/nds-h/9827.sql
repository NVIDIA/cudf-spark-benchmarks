
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_type,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_type
),
TopParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_mfgr,
        rp.p_type,
        RANK() OVER (ORDER BY total_cost DESC) AS rank
    FROM 
        RankedParts rp
)
SELECT 
    tp.p_partkey,
    tp.p_name,
    tp.p_mfgr,
    tp.p_type,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM 
    TopParts tp
LEFT JOIN 
    lineitem l ON tp.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    tp.rank <= 10
GROUP BY 
    tp.p_partkey, tp.p_name, tp.p_mfgr, tp.p_type
ORDER BY 
    revenue DESC;
