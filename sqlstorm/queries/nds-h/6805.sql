WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT 
        nation,
        s_suppkey,
        s_name,
        total_supply_cost
    FROM 
        RankedSuppliers
    WHERE 
        rank <= 3
),
OrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS total_orders,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    ts.nation,
    ts.s_suppkey,
    ts.s_name,
    os.c_custkey,
    os.c_name,
    os.total_order_value,
    os.total_orders,
    os.last_order_date
FROM 
    TopSuppliers ts
JOIN 
    lineitem l ON ts.s_suppkey = l.l_suppkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    OrderSummary os ON o.o_custkey = os.c_custkey
WHERE 
    l.l_shipdate >= '1997-01-01' 
    AND l.l_shipdate < '1998-01-01'
ORDER BY 
    ts.nation, ts.total_supply_cost DESC, os.total_order_value DESC
LIMIT 100;