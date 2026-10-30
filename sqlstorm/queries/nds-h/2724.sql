WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F' 
        AND l.l_shipdate > '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
top_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(lo.total_revenue) AS customer_revenue,
        ROW_NUMBER() OVER (ORDER BY SUM(lo.total_revenue) DESC) AS rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        ranked_orders lo ON o.o_orderkey = lo.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(lo.total_revenue) > 10000
),
supplier_parts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    r.r_name,
    COALESCE(tc.c_name, 'No Orders') AS customer,
    COALESCE(sp.s_name, 'No Supplier') AS supplier,
    COALESCE(t.total_revenue, 0) AS total_revenue,
    COALESCE(sc.total_supply_cost, 0) AS total_supply_cost
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    top_customers tc ON n.n_nationkey = tc.c_custkey
LEFT JOIN 
    ranked_orders t ON t.o_orderkey = tc.c_custkey
LEFT JOIN 
    supplier_parts sp ON sp.s_suppkey = tc.c_custkey
LEFT JOIN 
    supplier_parts sc ON sp.s_suppkey = sc.s_suppkey
WHERE 
    (t.total_revenue IS NOT NULL OR sc.total_supply_cost IS NOT NULL)
ORDER BY 
    r.r_regionkey, customer, supplier;