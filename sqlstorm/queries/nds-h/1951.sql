WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
), 
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 3
), 
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_brand,
        p.p_type,
        ps.ps_availqty,
        ps.ps_supplycost,
        SUM(l.l_quantity) AS total_sold
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey AND ps.ps_suppkey = l.l_suppkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey, p.p_brand, p.p_type, ps.ps_availqty, ps.ps_supplycost
), 
SupplierPartRanking AS (
    SELECT 
        tp.region_name,
        tp.nation_name,
        sp.p_brand,
        sp.p_type,
        sp.ps_availqty,
        sp.ps_supplycost,
        COALESCE(sp.total_sold, 0) AS total_sold,
        RANK() OVER (PARTITION BY tp.region_name ORDER BY COALESCE(sp.total_sold, 0) DESC) AS part_rank
    FROM 
        TopSuppliers tp
    JOIN 
        SupplierParts sp ON tp.s_suppkey = sp.ps_suppkey
)
SELECT 
    spr.region_name,
    spr.nation_name,
    spr.p_brand,
    spr.p_type,
    spr.ps_availqty,
    spr.ps_supplycost,
    spr.total_sold
FROM 
    SupplierPartRanking spr
WHERE 
    spr.part_rank <= 5
ORDER BY 
    spr.region_name, spr.nation_name, spr.total_sold DESC;
