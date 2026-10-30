WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUBSTRING(s.s_address, 1, 10) AS short_address,
        s.s_phone,
        s.s_acctbal,
        s.s_comment 
    FROM 
        supplier s 
    WHERE 
        LENGTH(s.s_comment) > 50
), 
NationDetails AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name,
        n.n_comment 
    FROM 
        nation n 
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
), 
PartSuppliers AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        ps.ps_availqty, 
        ps.ps_supplycost, 
        p.p_name,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost DESC) AS rank
    FROM 
        partsupp ps 
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
)
SELECT 
    sd.s_name,
    nd.n_name,
    nd.region_name,
    ps.p_name,
    ps.ps_supplycost,
    ps.ps_availqty,
    ps.rank 
FROM 
    SupplierDetails sd 
JOIN 
    NationDetails nd ON sd.s_nationkey = nd.n_nationkey 
JOIN 
    PartSuppliers ps ON sd.s_suppkey = ps.ps_suppkey 
WHERE 
    ps.rank = 1 
ORDER BY 
    nd.region_name, sd.s_name;
