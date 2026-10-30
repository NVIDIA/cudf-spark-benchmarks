WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_nationkey,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, 
        p.p_container, p.p_retailprice, p.p_comment
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
),
FinalReport AS (
    SELECT 
        h.p_name,
        h.p_retailprice,
        s.s_name AS supplier_name,
        s.s_acctbal,
        r.r_name AS region_name,
        ROW_NUMBER() OVER (PARTITION BY h.p_partkey ORDER BY s.s_acctbal DESC) AS supplier_position
    FROM 
        HighValueParts h
    JOIN 
        partsupp ps ON h.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    p_name,
    p_retailprice,
    supplier_name,
    s_acctbal,
    region_name
FROM 
    FinalReport
WHERE 
    supplier_position <= 3
ORDER BY 
    p_name, s_acctbal DESC;
