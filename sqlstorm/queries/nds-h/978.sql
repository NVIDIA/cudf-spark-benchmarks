WITH RankedSuppliers AS (
    SELECT 
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        rs.s_name,
        rs.total_cost,
        n.n_name
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    WHERE 
        rs.rank <= 3
),
CustomerOrders AS (
    SELECT 
        c.c_name,
        o.o_orderkey,
        SUM(l.l_extendedprice - l.l_extendedprice * l.l_discount) AS net_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY 
        c.c_name, o.o_orderkey
),
AggregatedRevenue AS (
    SELECT 
        c.c_name,
        SUM(co.net_revenue) AS total_revenue
    FROM 
        customerOrders co
    JOIN 
        customer c ON co.c_name = c.c_name
    GROUP BY 
        c.c_name
)

SELECT 
    ts.s_name AS supplier_name,
    ts.total_cost AS supplier_total_cost,
    ar.c_name AS customer_name,
    ar.total_revenue AS customer_total_revenue
FROM 
    TopSuppliers ts
FULL OUTER JOIN 
    AggregatedRevenue ar ON ts.n_name = ar.c_name
WHERE 
    (ts.total_cost IS NOT NULL OR ar.total_revenue IS NOT NULL)
ORDER BY 
    ts.total_cost DESC NULLS LAST, 
    ar.total_revenue DESC NULLS LAST;