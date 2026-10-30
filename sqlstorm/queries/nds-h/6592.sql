WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey
),
RegionSummary AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(c.c_acctbal) AS total_acct_balance
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        customer c ON s.s_suppkey = c.c_nationkey
    GROUP BY 
        r.r_name
)
SELECT 
    rs.s_name,
    rs.total_supply_value,
    rs.rank,
    rg.r_name,
    rg.nation_count,
    rg.total_acct_balance
FROM 
    RankedSuppliers rs
JOIN 
    RegionSummary rg ON rg.nation_count > 5
WHERE 
    rs.rank = 1
ORDER BY 
    rg.total_acct_balance DESC, rs.total_supply_value DESC
LIMIT 10;
