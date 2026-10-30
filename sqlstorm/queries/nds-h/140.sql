WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        AVG(s.s_acctbal) AS avg_account_balance,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        s.s_acctbal IS NOT NULL
        AND o.o_orderdate >= '1996-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name, 
        ss.total_supply_value,
        RANK() OVER (ORDER BY ss.total_supply_value DESC) AS supply_rank
    FROM 
        supplier s
    JOIN 
        SupplierStats ss ON s.s_suppkey = ss.s_suppkey
    WHERE 
        ss.total_supply_value > (SELECT AVG(total_supply_value) FROM SupplierStats)
)
SELECT 
    n.n_name AS nation,
    r.r_name AS region,
    hvs.s_name AS supplier_name,
    hvs.total_supply_value,
    hvs.supply_rank,
    (SELECT COUNT(*) FROM lineitem l WHERE l.l_suppkey = hvs.s_suppkey AND l.l_returnflag = 'R') AS total_returns
FROM 
    HighValueSuppliers hvs
JOIN 
    supplier s ON hvs.s_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    hvs.supply_rank <= 10
ORDER BY 
    hvs.supply_rank;