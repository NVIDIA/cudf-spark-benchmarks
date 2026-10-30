
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        s_suppkey,
        s_name,
        total_available_qty,
        avg_supply_cost
    FROM 
        SupplierStats
    WHERE 
        rank <= 3
),
OrderSummary AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.r_name,
    COALESCE(SUM(ts.total_available_qty), 0) AS total_available_qty,
    COALESCE(SUM(os.total_orders), 0) AS total_orders,
    COALESCE(SUM(os.total_spent), 0) AS total_spent,
    ROW_NUMBER() OVER (ORDER BY SUM(os.total_spent) DESC) AS region_rank
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    TopSuppliers ts ON s.s_suppkey = ts.s_suppkey
LEFT JOIN 
    OrderSummary os ON os.c_custkey = s.s_suppkey
WHERE 
    r.r_name IS NOT NULL
GROUP BY 
    r.r_name
HAVING 
    SUM(os.total_spent) > 10000
ORDER BY 
    region_rank;
