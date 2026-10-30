WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        AVG(s.s_acctbal) AS avg_account_balance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        ss.total_available_qty,
        ss.total_supply_cost,
        ss.avg_account_balance
    FROM 
        SupplierStats ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    WHERE 
        ss.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierStats)
),
NationSummary AS (
    SELECT 
        n.n_regionkey,
        SUM(hv.total_supply_cost) AS total_supply_cost_by_region,
        COUNT(DISTINCT hv.s_suppkey) AS supplier_count
    FROM 
        HighValueSuppliers hv
    JOIN 
        nation n ON hv.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_regionkey
)
SELECT 
    r.r_name,
    ns.total_supply_cost_by_region,
    ns.supplier_count,
    r.r_comment
FROM 
    region r
JOIN 
    NationSummary ns ON r.r_regionkey = ns.n_regionkey
ORDER BY 
    ns.total_supply_cost_by_region DESC;
