
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank,
        s.s_nationkey
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey
),
TopNationalSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        ns.n_name AS nation_name,
        s.s_suppkey,
        s.s_name,
        s.total_value
    FROM 
        RankedSuppliers s
    JOIN 
        nation ns ON s.s_nationkey = ns.n_nationkey
    JOIN 
        region r ON ns.n_regionkey = r.r_regionkey
    WHERE 
        s.supplier_rank <= 3
)
SELECT 
    tn.region_name,
    tn.nation_name,
    COUNT(tn.s_suppkey) AS number_of_top_suppliers,
    SUM(tn.total_value) AS total_value_of_suppliers
FROM 
    TopNationalSuppliers tn
GROUP BY 
    tn.region_name, tn.nation_name
ORDER BY 
    tn.region_name, total_value_of_suppliers DESC;
