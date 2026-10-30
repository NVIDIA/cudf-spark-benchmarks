WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        ns.n_name AS nation_name,
        rs.s_name AS supplier_name,
        rs.s_acctbal AS account_balance
    FROM 
        RankedSuppliers rs
    JOIN 
        nation ns ON rs.s_nationkey = ns.n_nationkey
    JOIN 
        region r ON ns.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 3
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        ps.ps_comment
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_name LIKE '%widget%'
)
SELECT 
    t.region_name,
    t.nation_name,
    t.supplier_name,
    SUM(pd.ps_supplycost * pd.ps_availqty) AS total_supply_cost,
    COUNT(pd.p_partkey) AS total_parts
FROM 
    TopSuppliers t
LEFT JOIN 
    PartDetails pd ON t.supplier_name = pd.ps_comment 
GROUP BY 
    t.region_name, 
    t.nation_name, 
    t.supplier_name
ORDER BY 
    t.region_name, 
    total_supply_cost DESC;
