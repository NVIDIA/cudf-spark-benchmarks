
WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        s.s_acctbal,
        LENGTH(s.s_comment) AS comment_length,
        UPPER(s.s_name) AS upper_s_name,
        CONCAT('Supplier: ', s.s_name, ', Address: ', s.s_address) AS full_address
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
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
        REPLACE(p.p_comment, 'dull', 'exciting') AS updated_comment
    FROM part p
),
CombinedDetails AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name,
        sd.nation_name,
        pd.p_partkey,
        pd.p_name,
        pd.p_brand,
        pd.p_type,
        pd.p_retailprice,
        pd.updated_comment,
        sd.full_address
    FROM SupplierDetails sd
    JOIN partsupp ps ON sd.s_suppkey = ps.ps_suppkey
    JOIN PartDetails pd ON ps.ps_partkey = pd.p_partkey
)
SELECT 
    cd.s_name,
    cd.nation_name,
    cd.p_name,
    cd.p_brand,
    cd.p_retailprice,
    cd.updated_comment,
    cd.full_address,
    CHAR_LENGTH(cd.full_address) AS full_address_length
FROM CombinedDetails cd
WHERE cd.p_retailprice > (
    SELECT AVG(p.p_retailprice) FROM part p
)
ORDER BY cd.nation_name, cd.p_retailprice DESC;
