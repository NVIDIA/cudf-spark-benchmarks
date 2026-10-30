
WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUBSTRING(s.s_comment, POSITION(' ' IN s.s_comment) + 1, LENGTH(s.s_comment)) AS filtered_comment
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
        p.p_retailprice,
        SUBSTRING(p.p_comment, POSITION(' ' IN p.p_comment) + 1, LENGTH(p.p_comment)) AS comment_substring
    FROM 
        part p
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_linenumber) AS total_lines,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    sd.s_name,
    pd.p_name,
    os.total_lines,
    os.total_revenue,
    CONCAT('Supplier ', sd.s_name, ' from ', sd.nation_name, ', ', sd.region_name, 
           ' supplies part ', pd.p_name, ' with a comment: ', pd.comment_substring) AS summary
FROM 
    SupplierDetails sd
JOIN 
    partsupp ps ON sd.s_suppkey = ps.ps_suppkey
JOIN 
    PartDetails pd ON ps.ps_partkey = pd.p_partkey
JOIN 
    OrderStats os ON ps.ps_partkey = pd.p_partkey
WHERE 
    sd.filtered_comment LIKE '%discount%'
AND 
    pd.p_retailprice > 100
ORDER BY 
    os.total_revenue DESC
LIMIT 10;
