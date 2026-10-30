
WITH RankedParts AS (
    SELECT 
        p_partkey,
        p_name,
        p_brand,
        p_retailprice,
        LENGTH(p_name) AS name_length,
        SUBSTRING(p_comment, 1, 15) AS short_comment,
        ROW_NUMBER() OVER (PARTITION BY p_brand ORDER BY p_retailprice DESC) AS brand_rank
    FROM 
        part
    WHERE 
        p_size IN (SELECT DISTINCT p_size FROM part WHERE p_type LIKE '%screw%')
),
FilteredSuppliers AS (
    SELECT 
        s_suppkey,
        s_name,
        s_nationkey,
        TRIM(s_address) AS trimmed_address
    FROM 
        supplier
    WHERE 
        CHAR_LENGTH(s_comment) > 50
),
CombinedData AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        rp.p_retailprice,
        fs.s_name,
        fs.trimmed_address,
        fs.s_nationkey
    FROM 
        RankedParts rp
    JOIN 
        FilteredSuppliers fs ON rp.p_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_suppkey = fs.s_suppkey)
)
SELECT 
    cd.p_partkey,
    cd.p_name,
    cd.p_brand,
    cd.p_retailprice,
    cd.s_name,
    cd.trimmed_address,
    n.n_name AS nation_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM 
    CombinedData cd
JOIN 
    nation n ON cd.s_nationkey = n.n_nationkey
JOIN 
    lineitem l ON cd.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderstatus = 'O'
GROUP BY 
    cd.p_partkey, cd.p_name, cd.p_brand, cd.p_retailprice, cd.s_name, cd.trimmed_address, n.n_name
HAVING 
    AVG(cd.p_retailprice) > 100.00
ORDER BY 
    cd.p_retailprice DESC, order_count DESC;
