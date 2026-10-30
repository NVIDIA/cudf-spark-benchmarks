WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
)
SELECT 
    p.p_name,
    p.p_brand,
    COALESCE(cs.total_spent, 0) AS total_spent_by_customer,
    COALESCE(o.order_rank, 0) AS order_rank,
    ts.total_supply_cost
FROM 
    part p
LEFT JOIN 
    CustomerSummary cs ON cs.total_spent > 0
LEFT JOIN 
    RankedOrders o ON o.o_orderkey = p.p_partkey
LEFT JOIN 
    TopSuppliers ts ON ts.total_supply_cost > (SELECT AVG(total_supply_cost) FROM TopSuppliers)
WHERE 
    p.p_size >= 10 AND
    (p.p_comment LIKE '%Fragile%' OR p.p_retailprice < 20)
ORDER BY 
    total_spent_by_customer DESC, 
    total_supply_cost DESC;