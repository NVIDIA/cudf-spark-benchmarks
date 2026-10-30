WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_price
    FROM 
        part p
), 
supplier_counts AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
),
final_results AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_mfgr,
        rp.p_brand,
        rp.p_type,
        rp.p_size,
        rp.p_container,
        rp.p_retailprice,
        rp.p_comment,
        sc.supplier_count
    FROM 
        ranked_parts rp
    JOIN 
        supplier_counts sc ON rp.p_partkey = sc.ps_partkey
    WHERE 
        rp.rank_price <= 5
)

SELECT 
    f.p_partkey,
    f.p_name,
    f.p_mfgr,
    f.p_brand,
    f.p_type,
    f.p_size,
    f.p_container,
    f.p_retailprice,
    f.p_comment,
    f.supplier_count
FROM 
    final_results f
WHERE 
    f.supplier_count > 3 
ORDER BY 
    f.p_retailprice DESC, f.supplier_count ASC;
