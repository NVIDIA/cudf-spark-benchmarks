WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation,
        r.r_name AS region,
        s.s_acctbal,
        LENGTH(s.s_comment) AS comment_length,
        TRIM(UPPER(s.s_comment)) AS trimmed_comment
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
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        LENGTH(p.p_comment) AS comment_length,
        REPLACE(p.p_comment, 'special', 'common') AS modified_comment
    FROM 
        part p
),
OrderAnalysis AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        SUBSTR(o.o_comment, 1, 10) AS short_comment,
        COUNT(l.l_orderkey) AS total_lines
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_comment
)
SELECT 
    sd.s_name,
    sd.nation,
    sd.region,
    pd.p_name,
    od.o_orderkey,
    od.o_orderdate,
    od.total_lines,
    sd.comment_length AS supplier_comment_length,
    pd.comment_length AS part_comment_length,
    CONCAT(sd.trimmed_comment, ' | ', pd.modified_comment) AS combined_comments
FROM 
    SupplierDetails sd
JOIN 
    partsupp ps ON sd.s_suppkey = ps.ps_suppkey
JOIN 
    PartDetails pd ON ps.ps_partkey = pd.p_partkey
JOIN 
    OrderAnalysis od ON od.o_orderkey = ps.ps_partkey
WHERE 
    sd.s_acctbal > 1000 AND 
    pd.p_size < 50
ORDER BY 
    sd.region, od.o_orderdate DESC;
