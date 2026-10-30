WITH PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_container,
        p.p_retailprice,
        ps.ps_supplycost,
        ps.ps_availqty,
        s.s_name AS supplier_name,
        s.s_nationkey,
        n.n_name AS nation_name,
        s.s_comment AS supplier_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        p.p_retailprice > 50.00
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_type,
    p.p_container,
    p.p_retailprice,
    ps.supplier_name,
    ps.ps_supplycost,
    ps.ps_availqty,
    ps.nation_name,
    ps.supplier_comment
FROM 
    PartSupplierDetails ps
JOIN 
    part p ON p.p_partkey = ps.p_partkey
WHERE 
    ps.rn <= 3
ORDER BY 
    p.p_partkey, ps.ps_supplycost DESC;
