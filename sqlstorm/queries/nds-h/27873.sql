WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_type,
        SUBSTRING(p.p_comment, 1, 15) AS short_comment,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY COUNT(DISTINCT ps.ps_suppkey) DESC) AS rn
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_type, p.p_comment
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders,
        ROW_NUMBER() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_mfgr,
    rp.p_type,
    cs.c_custkey,
    cs.c_name,
    rp.short_comment,
    cs.total_spent,
    cs.total_orders
FROM 
    RankedParts rp
JOIN 
    CustomerStats cs ON rp.supplier_count > 1
WHERE 
    rp.rn <= 5 AND cs.customer_rank <= 10
ORDER BY 
    rp.p_type, cs.total_spent DESC;
