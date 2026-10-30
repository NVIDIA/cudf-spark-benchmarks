WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        s.s_acctbal,
        s.s_comment,
        CONCAT(s.s_name, ' - ', s.s_address) AS full_info
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        TRIM(p.p_comment) AS trimmed_comment,
        LENGTH(p.p_comment) AS comment_length
    FROM 
        part p
),
OrderSummaries AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts_sold
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
)
SELECT 
    si.full_info,
    pd.p_name,
    pd.p_brand,
    pd.p_type,
    pd.p_size,
    pd.p_container,
    pd.p_retailprice,
    osv.total_revenue,
    osv.distinct_parts_sold,
    pd.comment_length,
    si.s_comment
FROM 
    SupplierInfo si
JOIN 
    partsupp ps ON si.s_suppkey = ps.ps_suppkey
JOIN 
    PartDetails pd ON ps.ps_partkey = pd.p_partkey
JOIN 
    OrderSummaries osv ON pd.p_partkey = osv.o_orderkey
WHERE 
    pd.trimmed_comment LIKE '%high%quality%'
ORDER BY 
    osv.total_revenue DESC, 
    pd.comment_length DESC;
