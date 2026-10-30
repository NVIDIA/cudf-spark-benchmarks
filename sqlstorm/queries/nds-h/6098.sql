
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        RANK() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    ORDER BY 
        total_cost DESC
    LIMIT 10
)
SELECT 
    o.order_rank,
    c.c_name AS customer_name,
    c.total_spent,
    s.s_name AS supplier_name,
    t.total_cost
FROM 
    RankedOrders o
JOIN 
    CustomerOrders c ON o.o_orderkey = c.order_count
JOIN 
    TopSuppliers t ON t.total_cost > 10000
JOIN 
    supplier s ON s.s_suppkey = t.s_suppkey
WHERE 
    o.order_rank <= 5
ORDER BY 
    c.total_spent DESC, t.total_cost ASC;
