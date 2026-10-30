
WITH SupplierParts AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        p.p_partkey, 
        p.p_name, 
        ps.ps_availqty, 
        ps.ps_supplycost, 
        LENGTH(p.p_name) AS part_name_length,
        CONCAT(s.s_name, ' - ', p.p_name) AS supplier_part_desc
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
RankedSuppliers AS (
    SELECT 
        s.*, 
        RANK() OVER (PARTITION BY s.s_suppkey ORDER BY s.ps_supplycost DESC) AS rank
    FROM 
        SupplierParts s
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    s.p_name AS part_name,
    s.ps_availqty,
    s.ps_supplycost,
    s.part_name_length,
    s.supplier_part_desc
FROM 
    RankedSuppliers s
JOIN 
    supplier sup ON s.s_suppkey = sup.s_suppkey
JOIN 
    partsupp ps ON s.p_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
JOIN 
    region r ON sup.s_nationkey = r.r_regionkey
JOIN 
    nation n ON sup.s_nationkey = n.n_nationkey
WHERE 
    s.rank <= 5 AND s.ps_availqty > 100
ORDER BY 
    r.r_name, n.n_name, s.s_name, s.ps_supplycost DESC;
