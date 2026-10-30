WITH OrderedProducts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        ps.ps_partkey,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        n.n_name AS nation_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank_nation
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 5000
),
FinalReport AS (
    SELECT 
        op.p_partkey,
        op.p_name,
        op.p_brand,
        sd.s_name AS supplier_name,
        sd.nation_name,
        op.ps_supplycost,
        op.rn
    FROM 
        OrderedProducts op
    JOIN 
        SupplierDetails sd ON op.ps_partkey = sd.s_suppkey
    WHERE 
        op.rn = 1
)
SELECT 
    f.p_partkey,
    f.p_name,
    f.p_brand,
    f.supplier_name,
    f.nation_name,
    f.ps_supplycost
FROM 
    FinalReport f
ORDER BY 
    f.ps_supplycost DESC;
