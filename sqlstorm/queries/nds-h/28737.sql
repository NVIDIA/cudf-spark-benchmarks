WITH RankedSuppliers AS (
    SELECT 
        s.s_name,
        s.s_nationkey,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY COUNT(DISTINCT ps.ps_partkey) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        rs.s_name,
        n.n_name AS nation_name,
        rs.total_parts
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    WHERE 
        rs.rn <= 3
),
PartDetails AS (
    SELECT 
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        COUNT(DISTINCT ps.ps_suppkey) AS available_suppliers
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_name, p.p_mfgr, p.p_brand
),
FinalBenchmark AS (
    SELECT 
        ts.nation_name,
        ts.s_name,
        pd.p_name,
        pd.p_mfgr,
        pd.p_brand,
        pd.available_suppliers,
        (SELECT AVG(p_retailprice) FROM part WHERE p_name = pd.p_name) AS avg_price
    FROM 
        TopSuppliers ts
    JOIN 
        PartDetails pd ON pd.available_suppliers > 5
)
SELECT 
    nation_name,
    s_name,
    p_name,
    p_mfgr,
    p_brand,
    available_suppliers,
    avg_price
FROM 
    FinalBenchmark
ORDER BY 
    nation_name, s_name, avg_price DESC;
