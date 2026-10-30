WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        c.c_name,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) as total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 1000000
),
PopularProducts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_quantity) as total_quantity_sold
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(l.l_quantity) > 500
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.c_name,
    t.s_name,
    p.p_name,
    p.total_quantity_sold,
    r.o_totalprice
FROM 
    RankedOrders r
LEFT JOIN 
    TopSuppliers t ON r.o_orderkey = t.s_suppkey
LEFT JOIN 
    PopularProducts p ON r.o_orderkey = p.p_partkey
WHERE 
    r.order_rank <= 10
ORDER BY 
    r.o_totalprice DESC, r.o_orderdate ASC;