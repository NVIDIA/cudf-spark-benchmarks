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
SupplierCost AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_brand = 'Brand#33' AND p.p_type LIKE '%Type%'
    GROUP BY 
        ps.ps_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > 1000
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    r.o_orderpriority,
    sc.total_supply_cost,
    co.order_count,
    co.total_spent
FROM 
    RankedOrders r
JOIN 
    SupplierCost sc ON r.o_orderkey % 5 = sc.ps_suppkey % 5
JOIN 
    CustomerOrders co ON co.order_count > 5
WHERE 
    r.order_rank <= 10
ORDER BY 
    r.o_orderdate DESC, r.o_totalprice DESC;
