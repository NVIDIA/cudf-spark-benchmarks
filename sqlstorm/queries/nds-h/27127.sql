WITH SupplierDetails AS (
    SELECT
        s.s_name,
        s.s_address,
        s.s_phone,
        n.n_name AS nation,
        r.r_name AS region,
        s.s_acctbal,
        LENGTH(s.s_comment) AS comment_length,
        LOWER(s.s_comment) AS formatted_comment
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
),
PartDetails AS (
    SELECT
        p.p_name,
        p.p_retailprice,
        p.p_comment,
        LENGTH(p.p_comment) AS comment_length,
        UPPER(p.p_type) AS formatted_type
    FROM
        part p
)
SELECT
    sd.s_name,
    sd.s_address,
    sd.s_phone,
    sd.nation,
    sd.region,
    sd.s_acctbal,
    pd.p_name,
    pd.p_retailprice,
    pd.formatted_type,
    sd.comment_length AS supplier_comment_length,
    pd.comment_length AS part_comment_length,
    CONCAT(sd.formatted_comment, ' | Part: ', pd.p_comment) AS full_comment
FROM
    SupplierDetails sd
CROSS JOIN
    PartDetails pd
WHERE
    sd.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    AND pd.p_retailprice < 50.00
ORDER BY
    sd.nation, sd.s_name, pd.p_name;
