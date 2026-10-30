
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY p.p_mfgr ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        r.r_name = 'ASIA' 
        AND l.l_shipdate >= DATE '1996-01-01' 
        AND l.l_shipdate < DATE '1997-01-01'
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr
),
TopParts AS (
    SELECT 
        rp.p_mfgr,
        SUM(rp.total_quantity) AS mfgr_total_quantity,
        SUM(rp.total_revenue) AS mfgr_total_revenue
    FROM 
        RankedParts rp
    GROUP BY 
        rp.p_mfgr
)
SELECT 
    tf.p_mfgr,
    tf.mfgr_total_quantity,
    tf.mfgr_total_revenue
FROM 
    TopParts tf
WHERE 
    tf.mfgr_total_revenue > (SELECT AVG(mfgr_total_revenue) FROM TopParts)
ORDER BY 
    tf.mfgr_total_revenue DESC;
