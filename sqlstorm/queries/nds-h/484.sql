WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS distinct_customers
    FROM 
        orders AS o
    JOIN 
        lineitem AS l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier AS s
    JOIN 
        partsupp AS ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        si.s_nationkey,
        ROW_NUMBER() OVER (PARTITION BY si.s_nationkey ORDER BY si.total_supply_cost DESC) AS rn,
        si.total_supply_cost
    FROM 
        SupplierInfo AS si
)
SELECT 
    r.r_name,
    COUNT(DISTINCT os.o_orderkey) AS total_orders,
    SUM(os.total_revenue) AS total_revenue,
    COUNT(DISTINCT ts.s_nationkey) AS top_supplier_count
FROM 
    region AS r
LEFT JOIN 
    nation AS n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    TopSuppliers AS ts ON n.n_nationkey = ts.s_nationkey AND ts.rn <= 3
LEFT JOIN 
    OrderSummary AS os ON os.o_orderkey IS NOT NULL 
WHERE 
    r.r_name IS NOT NULL
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT os.o_orderkey) > 10
ORDER BY 
    r.r_name;