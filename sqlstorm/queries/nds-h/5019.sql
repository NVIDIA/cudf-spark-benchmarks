WITH RankedCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
        RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_brand = 'Brand#23'
    GROUP BY 
        s.s_suppkey, s.s_name
),
FinalReport AS (
    SELECT 
        rc.c_name AS customer_name,
        rc.total_revenue AS customer_revenue,
        ts.s_name AS supplier_name,
        ts.total_supply_cost AS supplier_cost
    FROM 
        RankedCustomers rc
    JOIN 
        TopSuppliers ts ON rc.c_custkey % 100 = ts.s_suppkey % 100  
    WHERE 
        rc.revenue_rank <= 10
        AND ts.total_supply_cost > 1000
)
SELECT 
    customer_name,
    customer_revenue,
    supplier_name,
    supplier_cost
FROM 
    FinalReport
ORDER BY 
    customer_revenue DESC, supplier_cost ASC;