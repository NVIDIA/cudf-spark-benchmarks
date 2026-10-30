
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        LENGTH(p.p_comment) AS comment_length
    FROM 
        part p
    WHERE 
        p.p_retailprice > (
            SELECT AVG(p2.p_retailprice) 
            FROM part p2
        ) AND 
        p.p_brand LIKE CONCAT('Brand%', '%')
),
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal,
        fp.p_retailprice,
        rs.s_nationkey
    FROM 
        partsupp ps
    JOIN 
        RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey
    JOIN 
        FilteredParts fp ON ps.ps_partkey = fp.p_partkey
    WHERE 
        rs.rn <= 3
)
SELECT 
    n.n_name,
    COUNT(DISTINCT spd.ps_partkey) AS part_count,
    AVG(spd.p_retailprice) AS avg_price,
    SUM(spd.s_acctbal) AS total_acct_balance
FROM 
    SupplierPartDetails spd
JOIN 
    nation n ON spd.s_nationkey = n.n_nationkey
GROUP BY 
    n.n_name
ORDER BY 
    part_count DESC, total_acct_balance DESC;
