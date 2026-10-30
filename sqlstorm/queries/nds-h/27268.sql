WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        s.s_comment,
        CONCAT(s.s_name, ' ', s.s_comment) AS full_info,
        REPLACE(s.s_comment, 'good', 'excellent') AS improved_comment
    FROM 
        supplier s
),
RegionNation AS (
    SELECT
        r.r_regionkey,
        r.r_name,
        n.n_nationkey,
        n.n_name,
        CONCAT(n.n_name, ' from ', r.r_name) AS nation_region
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
),
PartsDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand,
        UPPER(p.p_name) AS upper_case_name,
        LOWER(p.p_comment) AS lower_case_comment,
        LENGTH(p.p_comment) AS comment_length
    FROM 
        part p
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS lineitem_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, 
        o.o_custkey
)
SELECT 
    pd.p_partkey,
    pd.upper_case_name,
    s.full_info,
    rn.nation_region,
    os.total_revenue,
    os.lineitem_count,
    LENGTH(pd.lower_case_comment) AS comment_length
FROM 
    PartsDetails pd
JOIN 
    SupplierDetails s ON pd.p_partkey % (s.s_suppkey + 1) = 0
JOIN 
    RegionNation rn ON rn.n_nationkey = s.s_nationkey
JOIN 
    OrderSummary os ON os.o_custkey = s.s_suppkey
WHERE 
    pd.comment_length > 20
ORDER BY 
    total_revenue DESC;
