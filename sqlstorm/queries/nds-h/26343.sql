WITH supplier_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        r.r_name AS region,
        s.s_acctbal,
        LENGTH(s.s_comment) AS comment_length,
        LOWER(s.s_name) AS normalized_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
part_details AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        (LENGTH(p.p_name) + LENGTH(p.p_comment)) AS combined_length
    FROM 
        part p
),
aggregated_data AS (
    SELECT 
        si.nation,
        si.region,
        COUNT(DISTINCT si.s_suppkey) AS supplier_count,
        SUM(si.s_acctbal) AS total_account_balance,
        AVG(pd.combined_length) AS avg_part_length
    FROM 
        supplier_info si
    JOIN 
        partsupp ps ON si.s_suppkey = ps.ps_suppkey
    JOIN 
        part_details pd ON ps.ps_partkey = pd.p_partkey
    GROUP BY 
        si.nation, si.region
)
SELECT 
    a.nation, 
    a.region, 
    a.supplier_count,
    a.total_account_balance,
    a.avg_part_length,
    CASE 
        WHEN a.avg_part_length < 50 THEN 'Short'
        WHEN a.avg_part_length BETWEEN 50 AND 100 THEN 'Medium'
        ELSE 'Long'
    END AS comment_length_category
FROM 
    aggregated_data a
ORDER BY 
    a.region, a.nation;
