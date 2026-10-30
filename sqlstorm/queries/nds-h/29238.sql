WITH RankedParts AS (
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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_per_brand
    FROM 
        part p
    WHERE 
        p.p_size > 0 AND 
        p.p_retailprice BETWEEN 100 AND 500
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
),
CombinedData AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        rp.rank_per_brand,
        l.l_extendedprice,
        l.l_discount,
        o.o_orderdate
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON l.l_partkey = p.p_partkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        RankedParts rp ON p.p_partkey = rp.p_partkey
    WHERE 
        rp.rank_per_brand <= 3
)
SELECT 
    region_name,
    nation_name,
    supplier_name,
    part_name,
    AVG(l_extendedprice * (1 - l_discount)) AS avg_sales_price,
    COUNT(*) AS order_count
FROM 
    CombinedData
GROUP BY 
    region_name, nation_name, supplier_name, part_name
ORDER BY 
    region_name, nation_name, supplier_name, avg_sales_price DESC;
