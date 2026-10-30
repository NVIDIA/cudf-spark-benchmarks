WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ps.ps_availqty,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_name LIKE '%widget%' 
        AND ps.ps_availqty > 100
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 5000
),
FinalResults AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_retailprice,
        rp.ps_availqty,
        fs.s_suppkey,
        fs.s_name,
        fs.nation_name
    FROM 
        RankedParts rp
    JOIN 
        FilteredSuppliers fs ON rp.rank <= 3
)
SELECT 
    *,
    CONCAT('Part: ', p_name, ' | Supplier: ', s_name, ' | Nation: ', nation_name) AS description
FROM 
    FinalResults
ORDER BY 
    p_retailprice DESC, s_name;
