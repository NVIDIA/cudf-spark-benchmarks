WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        LENGTH(s.s_comment) AS comment_length,
        LOWER(s.s_comment) AS lower_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_type,
        SUBSTRING(p.p_comment FROM 1 FOR 15) AS short_comment,
        CONCAT(p.p_name, ' - ', p.p_type) AS combined_name_type
    FROM 
        part p
),
Benchmarking AS (
    SELECT 
        sd.s_name,
        pd.p_name,
        pd.combined_name_type,
        sd.comment_length,
        pd.short_comment
    FROM 
        SupplierDetails sd
    JOIN 
        partsupp ps ON sd.s_suppkey = ps.ps_suppkey
    JOIN 
        PartDetails pd ON ps.ps_partkey = pd.p_partkey
    WHERE 
        sd.comment_length > 50
        AND pd.p_type LIKE '%plastic%'
)
SELECT 
    s_name,
    p_name,
    combined_name_type,
    short_comment,
    comment_length,
    CONCAT(s_name, ' supplies ', p_name, ' which is of type ', combined_name_type, ' and has a short comment: ', short_comment) AS descriptive_output
FROM 
    Benchmarking
ORDER BY 
    comment_length DESC, p_name;
