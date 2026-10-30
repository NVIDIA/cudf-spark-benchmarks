WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        s.s_nationkey,
        SUBSTRING(s.s_comment, 1, 20) AS short_comment,
        LENGTH(s.s_comment) AS comment_length
    FROM 
        supplier s
),
NationDetails AS (
    SELECT 
        n.n_nationkey, 
        n.n_name,
        r.r_name AS region_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
PartSupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        COUNT(ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    p.p_name, 
    p.p_mfgr, 
    p.p_brand, 
    n.n_name AS nation_name, 
    sd.s_name AS supplier_name, 
    sd.short_comment, 
    psd.total_available_qty, 
    psd.supplier_count
FROM 
    part p
JOIN 
    PartSupplierDetails psd ON p.p_partkey = psd.ps_partkey
JOIN 
    SupplierDetails sd ON psd.ps_suppkey = sd.s_suppkey
JOIN 
    NationDetails n ON sd.s_nationkey = n.n_nationkey
WHERE 
    LENGTH(p.p_comment) > 10
    AND psd.total_available_qty > 100
ORDER BY 
    p.p_name, sd.s_name;
