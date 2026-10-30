WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
    GROUP BY 
        o.o_orderkey
),
TopOrders AS (
    SELECT 
        *
    FROM 
        RankedOrders
    WHERE 
        revenue_rank <= 10
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighCostSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name
    FROM 
        SupplierInfo s
    WHERE 
        total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierInfo)
),
RevenueSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    t.o_orderkey,
    t.total_revenue,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    CASE 
        WHEN t.total_revenue IS NULL THEN 'No Revenue Recorded'
        WHEN t.total_revenue > 10000 THEN 'High Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM 
    TopOrders t
LEFT JOIN 
    RevenueSummary r ON t.o_orderkey = r.o_orderkey
LEFT JOIN 
    HighCostSuppliers s ON r.o_orderkey = s.s_suppkey
WHERE 
    t.total_revenue IS NOT NULL OR s.s_suppkey IS NOT NULL
ORDER BY 
    t.total_revenue DESC;