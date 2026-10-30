WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        LENGTH(p.p_name) AS name_length,
        LENGTH(p.p_comment) AS comment_length,
        RANK() OVER (PARTITION BY p.p_mfgr ORDER BY LENGTH(p.p_name) DESC) AS rank_by_name_length
    FROM 
        part p
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        SUBSTRING(s.s_comment FROM 1 FOR 20) AS short_comment,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
CombinedInfo AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        sd.s_name,
        sd.nation_name,
        rp.name_length,
        rp.comment_length
    FROM 
        RankedParts rp
    JOIN 
        partsupp ps ON rp.p_partkey = ps.ps_partkey
    JOIN 
        SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
    WHERE 
        rp.rank_by_name_length <= 5
)
SELECT 
    ci.p_partkey,
    ci.p_name,
    ci.s_name,
    ci.nation_name,
    ci.name_length,
    REPEAT('*', ci.comment_length) AS comment_visualization
FROM 
    CombinedInfo ci
ORDER BY 
    ci.name_length DESC, ci.p_name ASC;
