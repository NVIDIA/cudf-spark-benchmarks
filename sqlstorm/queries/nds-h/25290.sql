
WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        CONCAT(s.s_name, ' from ', s.s_address, ', ', n.n_name, ', ', r.r_name, ' (', s.s_comment, ')') AS supplier_info
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
PartSupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_name,
        p.p_brand,
        p.p_comment,
        ps.ps_availqty,
        ps.ps_supplycost,
        CONCAT(p.p_name, ' (', p.p_brand, ') supplied by ', 
            (SELECT STRING_AGG(s.s_name, ', ') 
             FROM SupplierDetails s 
             WHERE s.s_suppkey = ps.ps_suppkey),
            ' available:', CAST(ps.ps_availqty AS STRING), 
            ' cost:', CAST(ps.ps_supplycost AS STRING), 
            ' comment:', p.p_comment) AS part_supplier_info
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
)
SELECT 
    psd.part_supplier_info
FROM 
    PartSupplierDetails psd
WHERE 
    psd.ps_availqty > 100
ORDER BY 
    psd.ps_supplycost DESC;
