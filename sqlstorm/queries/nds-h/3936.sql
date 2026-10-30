
WITH SupplierTotals AS (
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
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
OrderLineDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_extended_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.r_name,
    nt.total_supply_cost,
    co.order_count,
    co.total_spent,
    old.total_extended_price,
    RANK() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(old.total_extended_price) DESC) AS price_rank
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    SupplierTotals nt ON n.n_nationkey = nt.s_suppkey
LEFT JOIN 
    CustomerOrders co ON nt.s_suppkey = co.c_custkey
LEFT JOIN 
    OrderLineDetails old ON co.order_count > 0
WHERE 
    nt.total_supply_cost IS NOT NULL
OR 
    co.total_spent IS NOT NULL
GROUP BY 
    r.r_name, nt.total_supply_cost, co.order_count, co.total_spent, old.total_extended_price, r.r_regionkey
HAVING 
    AVG(co.total_spent) > 1000
ORDER BY 
    r.r_name, price_rank;
