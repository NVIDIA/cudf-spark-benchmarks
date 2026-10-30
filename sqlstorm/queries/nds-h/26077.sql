WITH RankedSuppliers AS (
    SELECT 
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        s_name,
        nation_name,
        s_acctbal
    FROM 
        RankedSuppliers
    WHERE 
        rnk <= 3
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        CONCAT(p.p_name, ' (', CAST(ps.ps_availqty AS STRING), ' available, Cost: $', CAST(ps.ps_supplycost AS DECIMAL(12, 2)), ')') AS part_info
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
)
SELECT 
    ts.nation_name,
    ts.s_name,
    pd.part_info
FROM 
    TopSuppliers ts
JOIN 
    lineitem l ON l.l_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_name LIKE '%widget%') LIMIT 1)
JOIN 
    PartDetails pd ON pd.p_partkey = l.l_partkey
ORDER BY 
    ts.nation_name, ts.s_name;
