WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_suppkey) AS unique_suppliers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY 
        o.o_orderkey
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_nationkey
),
NationRevenue AS (
    SELECT 
        n.n_name,
        SUM(os.total_revenue) AS total_revenue,
        SUM(ss.total_supply_cost) AS total_supply_cost
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        SupplierSummary ss ON ss.s_nationkey = n.n_nationkey
    JOIN 
        OrderSummary os ON os.unique_suppliers = ss.s_suppkey
    GROUP BY 
        n.n_name
)
SELECT 
    n.n_name,
    n.total_revenue,
    n.total_supply_cost,
    (n.total_revenue - n.total_supply_cost) AS profit_margin
FROM 
    NationRevenue n
WHERE 
    n.total_revenue > 100000
ORDER BY 
    profit_margin DESC;