WITH RankedSuppliers AS (
    SELECT 
        s_name,
        s_nationkey,
        s_acctbal,
        RANK() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) AS rank
    FROM 
        supplier
),
HighValueSuppliers AS (
    SELECT 
        rs.s_name,
        rs.s_nationkey,
        n.n_name AS nation_name,
        rs.s_acctbal
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    WHERE 
        rs.rank <= 3
),
PartSupplierDetails AS (
    SELECT 
        p.p_name,
        p.p_brand,
        p.p_container,
        p.p_retailprice,
        hs.s_name AS supplier_name,
        hs.nation_name,
        hs.s_acctbal
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        HighValueSuppliers hs ON ps.ps_suppkey = hs.s_nationkey
)
SELECT 
    p_name,
    p_brand,
    COUNT(DISTINCT supplier_name) AS supplier_count,
    AVG(p_retailprice) AS avg_retail_price,
    MAX(s_acctbal) AS max_supplier_acctbal,
    nation_name
FROM 
    PartSupplierDetails
GROUP BY 
    p_name, p_brand, nation_name
ORDER BY 
    supplier_count DESC, avg_retail_price ASC;
